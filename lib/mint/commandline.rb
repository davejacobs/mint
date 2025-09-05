require "pathname"
require "yaml"
require "optparse"
require "fileutils"
require "shellwords"
require "active_support/core_ext/object/blank"

require_relative "./config"

module Mint
  module Commandline
    def self.run!(argv)
      command, help_message, config, files = Mint::Commandline.parse! argv
      case command.to_sym
      when :publish
        Mint::Commandline.publish!(files, config)
      when :help
        Mint::Commandline.help(help_message)
      else
        possible_binary = "mint-#{command}"
        if File.executable? possible_binary
          system "#{possible_binary} #{argv[1..-1].join ' '}"
        else
          $stderr.puts "Error: Unknown command '#{command}'"
          Mint::Commandline.help(help_message)
          exit 1
        end
      end
    end

    # Parses ARGV using OptionParser, mutating ARGV
    #
    # @param [Array] argv a list of arguments to parse
    # @return [Array] a list that contains the command, a help message,
    #   parsed config, and selected scopes
    def self.parse!(argv)
      commandline_options = {}

      parser = OptionParser.new do |cli|
        cli.banner = "Usage: mint [command] files [options]"

        cli.on "-t", "--template TEMPLATE", "Specify a template, which consists of a layout and a style (default: default)" do |t|
          commandline_options[:layout_name] = t
          commandline_options[:style_name] = t
        end

        cli.on "-l", "--layout LAYOUT", "Specify a layout (default: default)" do |l|
          commandline_options[:layout_name] = l
        end

        cli.on "-s", "--style STYLE", "Specify a style (default: default)" do |s|
          commandline_options[:style_name] = s
        end

        cli.on "-w", "--working-dir WORKING_DIR", "Specify a working directory outside the current directory (default: current directory)" do |w|
          commandline_options[:working_directory] = Pathname.new w
        end

        cli.on "-o", "--output-file FORMAT", "Specify the output file format with substitutions: \%{basename}, \%{original_extension}, \%{new_extension} (default: \%{basename}.\%{new_extension})" do |o|
          commandline_options[:output_file_format] = o
        end

        cli.on "-d", "--destination DESTINATION", "Specify a destination directory, relative to the root (default: current directory)" do |d|
          commandline_options[:destination_directory] = Pathname.new d
        end

        cli.on "-m", "--style-mode MODE", ["inline", "external", "original"], "Specify how styles are included (inline, external, original) (default: inline)" do |mode|
          commandline_options[:style_mode] = mode.to_sym
        end

        cli.on "--style-destination DESTINATION", "Create stylesheet in specified directory and link it" do |destination|
          commandline_options[:style_mode] = :external
          commandline_options[:style_destination_directory] = destination
        end

        cli.on "--preserve-structure", "Preserve source directory structure in destination (default: false)" do
          commandline_options[:preserve_structure] = true
        end
        
        cli.on "--navigation", "Make navigation information available to layout, so layout can show a navigation panel (default: false)" do
          commandline_options[:navigation] = true
        end
        
        cli.on "--navigation-drop LEVELS", Integer, "Drop the first N levels of the directory hierarchy from navigation (default: 0)" do |levels|
          commandline_options[:navigation_drop] = levels
        end
        
        cli.on "--navigation-depth DEPTH", Integer, "Maximum depth to show in navigation after dropping levels (default: 3)" do |depth|
          commandline_options[:navigation_depth] = depth
        end
        
        cli.on "--navigation-title TITLE", "Set the title for the navigation panel" do |title|
          commandline_options[:navigation_title] = title
        end
      end

      parser.parse! argv
      command = argv.shift || "help"
      
      
      # MINT_NO_PIPE is used for testing, to convince Mint
      # that STDIN isn't being used
      commandline_options[:files] =
        if $stdin.tty? || ENV["MINT_NO_PIPE"]
          argv
        else
          $stdin.each_line.reduce [] do |list, line|
            list.concat(Shellwords.split(line))
          end
        end
      
      if commandline_options[:style_mode] == :inline && commandline_options[:style_destination_directory]
        raise ArgumentError, "--style-mode inline and --style-destination cannot be used together"
      end
      
      files = commandline_options[:files].map {|f| Pathname.new(f).expand_path }
      commandline_config = Config.new(commandline_options)
      config = Mint.configuration.merge(commandline_config)

      [command, parser.help, config, files]
    end

    # Prints a help banner
    #
    # @param [String, #to_s] message a message to output
    # @return [void]
    def self.help(message)
      puts message
    end
    
    # For each file specified, publishes a new file based on configuration. The
    # new file 
    # Specifically: it publishes a document, using the document's accessors
    # to determine file placement and naming, and then renders its style.
    # This method will overwrite any existing content in a document's destination
    # files. The `render_style` option provides an easy way to stop Mint from
    # rendering a style, even if the document's style is not nil.
    #
    # @param [Array, #each] files a group of filenames
    # @param [Config] config a Config object with all configuration options
    # @return [void]
    def self.publish!(source_files, config)
      # Transform files into template-friendly format
      files_data = source_files.map do |source_file|
        title = Mint.extract_title_from_file(source_file)
        html_path = Mint::Helpers.resolve_output_file_path(source_file, config)
        {
          title: title,
          html_path: html_path,
          source_path: source_file
        }
      end
      
      # Build tree structure for navigation if navigation is enabled
      if config.navigation
        # Auto-detect common path depth if navigation_drop is not explicitly set
        auto_drop = config.navigation_drop == 0 ? Navigation.calculate_common_path_depth(files_data, config.working_directory) : config.navigation_drop
        tree_files_data = Navigation.build_file_tree(files_data, config.working_directory, config.navigation_depth, auto_drop)
      else
        tree_files_data = files_data
      end
      
      source_files.each_with_index do |source_file, idx|
        # Generate file-specific navigation with relative links
        file_specific_files_data = files_data.map do |file_data|
          if file_data[:source_path] == source_file
            # Self-reference, just use the title without a link
            file_data
          else
            # Create relative link from current file to this file
            relative_path = Mint::Helpers.relative_link_between_files(source_file, file_data[:source_path], config)
            file_data.merge(html_path: relative_path.to_s)
          end
        end
        
        # Use tree structure for navigation if enabled, otherwise use flat list
        navigation_data = config.navigation ? build_file_tree_for_current_file(tree_files_data, source_file, file_specific_files_data) : file_specific_files_data
        
        Mint.publish!(source_file, config, variables: { files: navigation_data }, render_style: idx == 0)
      end
    end
    
    # Builds a hierarchical tree structure from a flat list of files
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
