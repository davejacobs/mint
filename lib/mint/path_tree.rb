require "pathname"

module Mint
  class PathTree
    attr_reader :nodes
    
    def initialize(pathnames, config = nil)
      @pathnames = pathnames.map {|p| Pathname.new(p) }
      @config = config
      @nodes = build_tree_structure
    end
    
    def self.new_with_nodes(nodes)
      tree = allocate
      tree.instance_variable_set(:@nodes, nodes)
      tree
    end
    
    # Returns new PathTree with paths relative to reference_pathname
    def reoriented(reference_pathname)
      new_nodes = @nodes.map do |node|
        node.reoriented_relative_to(reference_pathname)
      end
      PathTree.new_with_nodes(new_nodes)
    end
    
    # Returns new PathTree with paths renamed using regex replacement
    def renamed(regex, replacement)
      new_nodes = @nodes.map do |node|
        node.renamed(regex, replacement)
      end
      PathTree.new_with_nodes(new_nodes)
    end
    
    # Returns new PathTree with n levels dropped from all paths
    def drop(n = 0)
      return self if n <= 0
      
      new_nodes = drop_levels_from_nodes(@nodes, n)
      PathTree.new_with_nodes(new_nodes)
    end
    
    # Returns new PathTree with common directory levels automatically dropped
    # Drops levels until there are multiple nodes at the top level
    def autodrop
      return self if @nodes.length > 1
      
      # Keep dropping levels while there's only one top-level node that's a directory,
      # as our goal is to remove "excess" subdirectories which are parents to all
      # specified files and directories.
      current_nodes = @nodes
      levels_dropped = 0
      while current_nodes.length == 1 && current_nodes.first.directory?
        current_nodes = current_nodes.first.children
        levels_dropped += 1
      end
      
      return self if levels_dropped == 0
      
      new_nodes = drop_levels_from_nodes(@nodes, levels_dropped)
      PathTree.new_with_nodes(new_nodes)
    end
    
    # Converts to array format expected by navigation templates
    def to_navigation_array
      flatten_nodes_to_array(@nodes)
    end
    
    # Apply navigation config (drop levels, max depth, etc.)
    def with_navigation_config(config)
      return self unless config
      
      result = self
      
      # Apply autodrop if enabled (mutually exclusive with explicit drop)
      if config.navigation_autodrop
        result = result.autodrop
      else
        # Apply explicit drop levels (only if autodrop is not enabled)
        drop_levels = config.navigation_drop || 0
        if drop_levels > 0
          result = result.drop(drop_levels)
        end
      end
      
      # Apply max depth filtering - depth is relative to what remains after dropping
      max_depth = config.navigation_depth || 3
      # The actual max depth is the minimum depth in the result + the navigation_depth limit
      min_depth_after_drop = result.nodes.map(&:depth).min || 0
      absolute_max_depth = min_depth_after_drop + max_depth - 1
      filtered_nodes = apply_depth_filter(result.nodes, absolute_max_depth)
      PathTree.new_with_nodes(filtered_nodes)
    end
    
    private
    
    def build_tree_structure
      return [] if @pathnames.empty?
      
      tree = {}
      @pathnames.each do |pathname|
        parts = pathname.to_s.split('/').reject(&:empty?)
        
        current_level = tree
        parts.each_with_index do |part, idx|
          # Build the full path up to this point
          path_so_far = parts[0..idx].join('/')
          
          current_level[part] ||= { 
            children: {}, 
            pathname: Pathname.new(path_so_far), 
            depth: idx,
            is_file: false
          }
          
          # If this is the last part (the file), mark it as a file
          if idx == parts.length - 1
            current_level[part][:is_file] = true
            current_level[part][:pathname] = pathname
          end
          
          current_level = current_level[part][:children]
        end
      end
      
      convert_hash_to_nodes(tree, 0)
    end
    
    def convert_hash_to_nodes(tree_hash, depth)
      result = []
      
      # Sort keys: directories first, then files, alphabetically within each
      sorted_keys = tree_hash.keys.sort do |a, b|
        node_a = tree_hash[a]
        node_b = tree_hash[b]
        
        a_is_directory = !node_a[:is_file]
        b_is_directory = !node_b[:is_file]
        
        if a_is_directory && !b_is_directory
          -1  # a is directory, b is file - a comes first
        elsif !a_is_directory && b_is_directory
          1   # a is file, b is directory - b comes first
        else
          a <=> b  # both same type - sort alphabetically
        end
      end
      
      sorted_keys.each do |key|
        node_data = tree_hash[key]
        children = convert_hash_to_nodes(node_data[:children], depth + 1)
        
        # Now all nodes have consistent pathnames
        pathname = node_data[:pathname]
        
        result << PathTreeNode.new(pathname, children: children, depth: depth)
      end
      
      result
    end
    
    def flatten_nodes_to_array(nodes, depth = 0)
      result = []
      
      nodes.each do |node|
        if node.file?
          # This is a file node
          result << {
            title: node.title,
            html_path: node.pathname.to_s,
            source_path: node.pathname.to_s,
            depth: depth
          }
        else
          # This is a directory node  
          result << {
            title: node.title,
            html_path: nil,
            source_path: nil,
            depth: depth,
            is_directory: true
          }
          
          # Add children recursively
          result.concat(flatten_nodes_to_array(node.children, depth + 1))
        end
      end
      
      result
    end
    
    
    def drop_levels_from_nodes(nodes, levels_to_drop)
      return nodes if levels_to_drop <= 0
      
      result = []
      
      nodes.each do |node|
        if node.directory? && levels_to_drop > 0
          # If this is a directory and we still have levels to drop,
          # recursively drop from children and add them directly
          result.concat(drop_levels_from_nodes(node.children, levels_to_drop - 1))
        else
          # Either this is a file, or we've dropped enough levels
          # Adjust the pathname and depth for the dropped levels
          dropped_pathname = adjust_pathname_for_drop(node.pathname, levels_to_drop)
          new_depth = [node.depth - levels_to_drop, 0].max
          
          new_children = drop_levels_from_nodes(node.children, levels_to_drop)
          result << PathTreeNode.new(dropped_pathname, children: new_children, depth: new_depth, title: node.title)
        end
      end
      
      result
    end
    
    def adjust_pathname_for_drop(pathname, levels_to_drop)
      parts = pathname.to_s.split('/').reject(&:empty?)
      return pathname if levels_to_drop >= parts.length
      
      dropped_parts = parts.drop(levels_to_drop)
      return Pathname.new('.') if dropped_parts.empty?
      
      Pathname.new(dropped_parts.join('/'))
    end
    
    def apply_depth_filter(nodes, max_depth)
      nodes.select {|node| node.depth <= max_depth }
    end
  end

  class PathTreeNode
    attr_reader :pathname, :children, :depth, :title
    
    def initialize(pathname, children: [], depth: 0, title: nil)
      @pathname = Pathname.new(pathname)
      @children = children  
      @depth = depth
      @title = title || extract_title
    end
    
    def reoriented_relative_to(reference_pathname)
      new_pathname = calculate_relative_path(@pathname, reference_pathname)
      new_children = @children.map {|child| child.reoriented_relative_to(reference_pathname) }
      PathTreeNode.new(new_pathname, children: new_children, depth: @depth, title: @title)
    end
    
    def renamed(regex, replacement)
      new_pathname_str = @pathname.to_s.gsub(regex, replacement)
      new_pathname = Pathname.new(new_pathname_str)
      new_children = @children.map {|child| child.renamed(regex, replacement) }
      PathTreeNode.new(new_pathname, children: new_children, depth: @depth, title: @title)
    end
    
    def directory?
      @children.any?
    end
    
    def file?
      !directory?
    end
    
    private
    
    def extract_title
      if @pathname.file?
        Document.extract_title_from_file(@pathname)
      else
        @pathname.basename.to_s
      end
    end
    
    def calculate_relative_path(target_pathname, reference_pathname)
      reference_dir = reference_pathname.file? ? reference_pathname.dirname : reference_pathname
      target_pathname.relative_path_from(reference_dir) rescue target_pathname
    end
  end
end