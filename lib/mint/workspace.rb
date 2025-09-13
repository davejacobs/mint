require "pathname"
require "fileutils"

require_relative "./document"
require_relative "./helpers"
require_relative "./css_parser"

module Mint
  class Workspace
    def initialize(markdown_paths, config)
      @config = config
      @documents = []
      
      # 1. Create destination_html_paths, mapped 1:1 with markdown_paths,
      #    and autodropping any directories that are common to all files,
      #    if config.autodrop is on.
      # 2. Zip markdown_paths and destination_html_paths together so they
      #    are paired
      # 3. For each pair, create a document with the source and destination
      #    paths, and create navigation tree JSON that's relative to
      #    the specific document at hand
      #
      # NOTE: All directories at this stage are relative so that they can be
      # concatenated and manipulated. The working directory is passed into
      # the Document, which is where it's used to calculate its actual
      # absolute destination.
      
      autodrop_levels = calculate_autodrop_levels_for(markdown_paths)
      style_path = find_style_path(@config.style_name)
      layout_path = find_layout_path(@config.layout_name)
      style_destination_path = @config.destination_directory + @config.style_destination_directory

      markdown_paths.each_with_index do |path, index|
        destination_path = destination_path_for(path,
                                                autodrop_levels: autodrop_levels,
                                                preserve_structure: @config.preserve_structure,
                                                output_file_format: @config.output_file_format)

        @documents << Document.new(
          working_directory: @config.working_directory,
          source_path: path,
          destination_path: destination_path,
          destination_directory_path: @config.destination_directory,
          layout_path: layout_path,
          style_path: style_path,
          style_destination_path: style_destination_path,
          style_mode: @config.style_mode,
          insert_title_heading: @config.insert_title_heading,
          transform_links: lambda {|link_basename| update_basename(link_basename, new_extension: "html", format_string: @config.output_file_format) },
          render_style: index == 0
        )
      end
    end
    
    def publish!
      if @config.navigation
        @documents.map do |document|
          document.publish!(show_navigation: true, navigation: @documents, navigation_depth: @config.navigation_depth, navigation_title: @config.navigation_title)
        end
      else
        @documents.map do |document|
          document.publish!(show_navigation: false, navigation: nil, navigation_depth: 0, navigation_title: nil)
        end
      end
    end
    
    # Returns the style path relative to the working directory
    # 
    # @param [String] style_name name of the style to find
    # @return [Pathname] the style path relative to the working directory
    def find_style_path(style_name)
      style_source = Style.find_by_name(style_name)
      raise StyleNotFoundException, "Style '#{style_name}' does not exist." unless style_source
      
      if style_source.absolute?
        style_source.relative_path_from(@config.working_directory)
      else
        style_source
      end
    end
    
    # Returns the layout path relative to the working directory
    # 
    # @param [String] layout_name name of the layout to find
    # @return [Pathname] the layout path relative to the working directory
    def find_layout_path(layout_name)
      layout_source = Layout.find_by_name(layout_name) || 
                      Layout.find_by_name(Config::DEFAULT_LAYOUT_NAME)
      raise LayoutNotFoundException, "Layout '#{layout_name}' does not exist." unless layout_source
      
      if layout_source.absolute?
        layout_source.relative_path_from(@config.working_directory)
      else
        layout_source
      end
    end
    
    # Updates the basename of a filename with a new extension and format string
    # 
    # @param [String] filename the filename to update
    # @param [String] new_extension the new extension to use
    # @param [String] format_string the format string to use
    # @return [String] the updated filename
    def update_basename(filename, new_extension:, format_string:)
      filename_no_ext = File.basename(filename, ".*")
      format_string % {
        name: filename_no_ext,
        ext: new_extension,
        original_ext: File.extname(filename)[1..-1]
      }
    end

    # Updates the basename of a path with a new extension and format string
    # 
    # @param [Pathname] path the path to update
    # @param [String] new_extension the new extension to use
    # @param [String] format_string the format string to use
    # @return [Pathname] the updated path
    def update_path_basename(path, new_extension:, format_string:)
      path.sub(path.basename.to_s, update_basename(path.basename, new_extension: new_extension, format_string: format_string))
    end
    
    # Calculates the number of levels to "autodrop" from the paths. Autodropping is dropping
    # any parent directories that are common to all paths. This makes it easy for users to pass
    # in directories not in the current working directory and have them automatically removed
    # from the final output paths. Autodropping is only done if @config.autodrop is true. 
    # 
    # @param [Array<Pathname>] markdown_paths the paths to calculate the autodrop levels for
    # @return [Integer] the number of levels to drop
    def calculate_autodrop_levels_for(markdown_paths)
      return 0 unless @config.autodrop
      return 0 if markdown_paths.length <= 1
      
      # Find common parent directories by splitting paths and finding common prefix
      path_parts = markdown_paths.map {|path| path.to_s.split('/').reject(&:empty?) }
      return 0 if path_parts.empty?
      
      # Find the minimum length to avoid index errors
      min_length = path_parts.map(&:length).min
      return 0 if min_length == 0
      
      # Find common prefix length
      common_prefix_length = 0
      (0...min_length).each do |i|
        if path_parts.all? {|parts| parts[i] == path_parts.first[i] }
          common_prefix_length = i + 1
        else
          break
        end
      end
      
      # Only drop if there's a meaningful common prefix and it leaves at least one level
      if common_prefix_length > 0 && path_parts.any? {|parts| parts.length > common_prefix_length }
        common_prefix_length
      else
        0
      end
    end

    def destination_path_for(path, autodrop_levels:, preserve_structure:, output_file_format:)
      if preserve_structure
        # Keep directory structure, but apply autodrop if enabled and convert extension to HTML
        dropped_path = Helpers.drop_pathname(path, autodrop_levels)
        update_path_basename(dropped_path, new_extension: "html", format_string: output_file_format)
      else
        # Flatten all files directly into destination directory (no subdirectories)
        Pathname.new(update_basename(path.basename, new_extension: "html", format_string: output_file_format))
      end
    end
  end
end