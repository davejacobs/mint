require "pathname"

module Mint
  # Handles file tree building and navigation structure for Mint documents
  module Navigation
    # Builds a hierarchical tree structure from a flat list of files
    #
    # @param [Array] files_data array of file data hashes
    # @param [Pathname] working_directory the working directory
    # @param [Integer] max_depth maximum depth to show (default: 3)
    # @param [Integer] drop_levels number of levels to drop from the beginning (default: 0)
    # @return [Array] hierarchical tree structure
    def self.build_file_tree(files_data, working_directory, max_depth = 3, drop_levels = 0)
      tree = {}
      
      files_data.each do |file_data|
        source_path = Pathname.new(file_data[:source_path])
        # Get relative path from working directory (source structure, not destination)
        begin
          # Ensure both paths are expanded to handle relative vs absolute path issues
          expanded_source = source_path.expand_path
          expanded_working = working_directory.expand_path
          relative_path = expanded_source.relative_path_from(expanded_working)
        rescue ArgumentError
          # If paths are not comparable, use just the filename
          relative_path = Pathname.new(source_path.basename)
        end
        
        parts = relative_path.to_s.split('/').reject(&:empty?)
        
        # Drop the first N levels as requested
        if drop_levels > 0 && parts.length > drop_levels
          parts = parts.drop(drop_levels)
        elsif drop_levels > 0
          # If we're dropping more levels than exist, skip this file
          next
        end
        
        # Limit depth after dropping levels
        parts = parts.take(max_depth) if parts.length > max_depth
        
        current_level = tree
        parts.each_with_index do |part, idx|
          current_level[part] ||= { children: {}, file_data: nil, depth: idx }
          
          # If this is the last part (the file), store the file data
          if idx == parts.length - 1
            current_level[part][:file_data] = file_data.merge(depth: idx)
          end
          
          current_level = current_level[part][:children]
        end
      end
      
      # Convert tree structure to flat list with depth information
      flatten_tree(tree, 0)
    end
    
    # Converts tree structure to flat array with depth information
    #
    # @param [Hash] tree the tree structure to flatten
    # @param [Integer] depth current depth level
    # @return [Array] flat array with depth information
    def self.flatten_tree(tree, depth = 0)
      result = []
      
      # Sort keys by type (directories first, then files) and then alphabetically within each type
      sorted_keys = tree.keys.sort do |a, b|
        node_a = tree[a]
        node_b = tree[b]
        
        # Determine if each is a directory (has children) or file (has file_data)
        a_is_directory = !node_a[:children].empty?
        b_is_directory = !node_b[:children].empty?
        
        if a_is_directory && !b_is_directory
          -1  # a is directory, b is file - a comes first
        elsif !a_is_directory && b_is_directory
          1   # a is file, b is directory - b comes first
        else
          a <=> b  # both same type - sort alphabetically
        end
      end
      
      sorted_keys.each do |key|
        node = tree[key]
        
        if node[:file_data]
          # This is a file node - add it directly
          result << node[:file_data].merge(depth: depth)
        elsif !node[:children].empty?
          # This is a directory node with children - add as a non-clickable header
          result << {
            title: key,
            html_path: nil,
            source_path: nil,
            depth: depth,
            is_directory: true
          }
          
          # Add children recursively
          result.concat(flatten_tree(node[:children], depth + 1))
        end
      end
      
      result
    end
    
    # Builds tree structure with relative links for the current file
    #
    # @param [Array] tree_files_data hierarchical tree structure
    # @param [String] current_source_file path to current file being processed
    # @param [Array] file_specific_files_data flat files data with relative links
    # @return [Array] tree structure with relative links for current file
    def self.build_file_tree_for_current_file(tree_files_data, current_source_file, file_specific_files_data)
      # Map the tree structure to use the relative links from file_specific_files_data
      relative_links_map = {}
      file_specific_files_data.each do |file_data|
        relative_links_map[file_data[:source_path]] = file_data[:html_path]
      end
      
      tree_files_data.map do |tree_item|
        if tree_item[:is_directory]
          tree_item
        else
          tree_item.merge(html_path: relative_links_map[tree_item[:source_path]] || tree_item[:html_path])
        end
      end
    end
    
    # Calculates the depth of common subdirectories for all files
    #
    # @param [Array] files_data array of file data hashes
    # @param [Pathname] working_directory the working directory
    # @return [Integer] number of common directory levels to drop
    def self.calculate_common_path_depth(files_data, working_directory)
      return 0 if files_data.empty?
      
      # Get directory paths for all files (excluding the filename)
      directory_paths = files_data.map do |file_data|
        source_path = Pathname.new(file_data[:source_path])
        begin
          expanded_source = source_path.expand_path
          expanded_working = working_directory.expand_path
          relative_path = expanded_source.relative_path_from(expanded_working)
          parts = relative_path.to_s.split('/').reject(&:empty?)
          # Remove the filename (last part) to get just directory structure
          parts.length > 1 ? parts[0..-2] : []
        rescue ArgumentError
          # If paths are not comparable, return empty
          []
        end
      end
      
      return 0 if directory_paths.empty?
      
      # If any files are at root level (no directory), don't drop anything
      return 0 if directory_paths.any?(&:empty?)
      
      # Find the common prefix by comparing all directory paths
      common_parts = []
      min_length = directory_paths.map(&:length).min
      
      (0...min_length).each do |i|
        parts_at_index = directory_paths.map { |path| path[i] }.uniq
        if parts_at_index.length == 1
          # All paths have the same part at this index
          common_parts << parts_at_index.first
        else
          # Paths diverge at this index
          break
        end
      end
      
      # Return the number of common directory levels
      # For example, if all files are in "examples/digital-garden/..."
      # common_parts will be ["examples", "digital-garden"] and we return 2
      common_parts.length
    end
  end
end