require "pathname"
require_relative "./navigation"
require_relative "./helpers"

module Mint
  # Handles the complete navigation data processing pipeline
  # Follows a logical progression of steps to transform raw file lists
  # into structured navigation data suitable for layouts
  class NavigationProcessor
    # Main processing pipeline that follows the logical progression:
    #
    # 1. List all files
    # 2. Create a relative list of all files for each file to each file
    # 3. Auto-drop any common ancestors of all files in navigation structure passed into layout
    # 4. Create a navigation tree, dropping anything the user has specified if it's beyond autodrop, and only going to --depth
    # 5. Rewrite all .md URLs in the nav list to .html using the output_file_format config
    # 6. Rewrite all .md URLs in the content itself to .html using the output_file_format_config (handled in mint.rb)
    # 7. Properly calculate the relative path of the original stylesheet(s) (in --style-mode original) from each file, for linking (handled in mint.rb)
    #
    # @param [Array] source_files array of source file paths
    # @param [Config] config configuration object
    # @return [Hash] processed navigation data with metadata
    def self.process_navigation_data(source_files, config)
      # Step 1: List all files - Create initial file data structures
      files_data = create_initial_files_data(source_files, config)
      
      # Step 2: Create a relative list of all files for each file to each file
      # (This will be done per-file later in the pipeline)
      
      # Step 3: Auto-drop any common ancestors of all files in navigation structure
      auto_drop = calculate_auto_drop_level(files_data, config)
      
      # Step 4: Create a navigation tree, applying user-specified and auto-drop levels, respecting depth
      tree_files_data = build_navigation_tree(files_data, config, auto_drop)
      
      # Step 5: Rewrite all .md URLs in the nav list to .html using the output_file_format config
      # (Already handled in create_initial_files_data)
      
      {
        files_data: files_data,
        tree_files_data: tree_files_data,
        auto_drop: auto_drop
      }
    end
    
    # Processes navigation data for a specific current file
    # 
    # @param [String] current_source_file path to the current file being processed
    # @param [Hash] navigation_data the result from process_navigation_data
    # @param [Config] config configuration object
    # @return [Array] navigation data with relative links for the current file
    def self.process_navigation_for_current_file(current_source_file, navigation_data, config)
      files_data = navigation_data[:files_data]
      tree_files_data = navigation_data[:tree_files_data]
      
      # Step 2: Create relative links from current file to all other files
      file_specific_files_data = create_relative_links_for_current_file(current_source_file, files_data, config)
      
      # Apply tree structure if navigation is enabled, otherwise use flat list
      if config.navigation
        Navigation.build_file_tree_for_current_file(tree_files_data, current_source_file, file_specific_files_data)
      else
        file_specific_files_data
      end
    end
    
    private
    
    # Step 1: Create initial file data structures
    # Handles URL rewriting from .md to .html based on output_file_format
    def self.create_initial_files_data(source_files, config)
      source_files.map do |source_file|
        source_path = Pathname.new(source_file)
        
        # Calculate destination path based on preserve_structure setting
        if config.preserve_structure
          relative_path = source_path.relative_path_from(config.working_directory) rescue source_path
          destination_file_basename = Mint::Helpers.format_output_file(relative_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
          destination_relative_path = relative_path.dirname + destination_file_basename
        else
          destination_file_basename = Mint::Helpers.format_output_file(source_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
          destination_relative_path = Pathname.new(destination_file_basename)
        end
        
        {
          title: Mint.extract_title_from_file(source_file),
          html_path: destination_relative_path.to_s,
          source_path: source_file
        }
      end
    end
    
    # Step 2: Create relative links from current file to all other files
    def self.create_relative_links_for_current_file(current_source_file, files_data, config)
      files_data.map do |file_data|
        if file_data[:source_path] == current_source_file
          # Self-reference, just use the title without a link
          file_data
        else
          # Create relative link from current file to this file
          relative_path = Mint::Helpers.relative_link_between_files(current_source_file, file_data[:source_path], config)
          file_data.merge(html_path: relative_path.to_s)
        end
      end
    end
    
    # Step 3: Calculate auto-drop level for common ancestors
    def self.calculate_auto_drop_level(files_data, config)
      if config.navigation_drop == 0
        Navigation.calculate_common_path_depth(files_data, config.working_directory)
      else
        config.navigation_drop
      end
    end
    
    # Step 4: Build navigation tree with proper dropping and depth limits
    def self.build_navigation_tree(files_data, config, auto_drop)
      if config.navigation
        Navigation.build_file_tree(files_data, config.working_directory, config.navigation_depth, auto_drop)
      else
        files_data
      end
    end
  end
end