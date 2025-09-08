require "pathname"
require "fileutils"
require_relative "./document"
require_relative "./path_tree"
require_relative "./css_parser"

module Mint
  class Workspace
    def initialize(markdown_files, config)
      @markdown_files = markdown_files.map {|f| Pathname.new(f) }
      @config = config
      @style_path = find_style_path
      @layout_path = find_layout_path
      
      @path_tree = PathTree.new(@markdown_files, @config)
    end
    
    def publish!
      create_external_style_mode if @config.style_mode == :external
      @markdown_files.each_with_index.map do |markdown_file, index|
        publish_document!(markdown_file, render_style: index == 0)
      end
    end

    def publish_document!(markdown_file, render_style: true)
      variables = build_variables_for_file(markdown_file)
      options = build_rendering_options(markdown_file, render_style)
      
      html_content = Document.publish!(
        markdown_path: markdown_file,
        style_path: @style_path,
        layout_path: @layout_path, 
        variables: variables,
        options: options
      )
      
      # Formatting this way to make it clear that we return the destination path
      destination_path = write_file(markdown_file, html_content)
      destination_path
    end

    def destination_path_for(source_file)
      source_pathname = Pathname.new(source_file)
      destination_directory = @config.destination_directory.expand_path(@config.working_directory)
      
      if @config.preserve_structure
        relative_path = source_pathname.relative_path_from(@config.working_directory) rescue source_pathname
        destination_basename = Workspace.format_output_file(relative_path.basename.to_s, 
          new_extension: "html", 
          format_string: @config.output_file_format
        )
        destination_path = destination_directory + relative_path.dirname + destination_basename
      else
        destination_basename = Workspace.format_output_file(source_pathname.basename.to_s,
          new_extension: "html", 
          format_string: @config.output_file_format
        )
        destination_path = destination_directory + destination_basename
      end
      
      destination_path
    end

    def self.format_output_file(file, new_extension: "html", format_string: "%{name}.%{ext}")
      basename = File.basename(file, ".*")
      original_extension = File.extname(file)[1..-1] || ""
      format_string % {
        name: basename,
        ext: new_extension,
        original_ext: original_extension
      }
    end
    
    private
    
    def build_variables_for_file(current_file)
      # Get navigation tree relative to current file, then rename to HTML
      navigation_tree = @path_tree.with_navigation_config(@config)
                                   .reoriented(current_file)
                                   .renamed(/\.md$/, '.html')
      
      # Extract title only when --file-title is enabled
      title = @config.file_title ? extract_title_for_file(current_file) : nil
      
      navigation_array = navigation_tree.to_navigation_array
      
      {
        files: navigation_array,
        title: title,
        source_file: current_file.to_s,
        working_directory: @config.working_directory,
        config: @config,
        show_navigation: @config.navigation,
        navigation_title: @config.navigation_title
      }
    end
    
    def build_rendering_options(current_file, render_style)
      options = {
        output_file_format: @config.output_file_format,
        style_mode: @config.style_mode
      }
      
      # Handle original style mode - need CSS link tags
      if @config.style_mode == :original
        destination_path = destination_path_for(current_file)
        css_file_paths = CssParser.resolve_css_files(@style_path.to_s, destination_path.to_s)
        options[:stylesheet_tag] = CssParser.generate_link_tags(css_file_paths)
        options[:style_mode] = :original  # Override to prevent Document from generating its own
      end
      
      options
    end
    
    def extract_title_for_file(file_path)
      if @config.file_title
        File.basename(file_path, '.*').sub(/\.md$/, '')
      else
        Document.extract_title_from_file(file_path)
      end
    end
    
    def write_file(source_file, content)
      destination_path = destination_path_for(source_file)
      destination_path.dirname.mkpath
      destination_path.open("w+") do |f|
        f << content
      end
      destination_path
    end
    
    def find_style_path
      style_source = Style.find_by_name(@config.style_name)
      raise StyleNotFoundException, "Style '#{@config.style_name}' does not exist." unless style_source
      style_source
    end
    
    def find_layout_path
      layout_source = Layout.find_by_name(@config.layout_name) || 
                      Layout.find_by_name(Config::DEFAULT_LAYOUT_NAME)
      raise LayoutNotFoundException, "Layout '#{@config.layout_name}' does not exist." unless layout_source
      layout_source
    end
    
    def create_external_style_mode
      return unless @config.style_mode == :external
      
      style_destination_directory = @config.style_destination_directory
      style_output_file = style_destination_directory + "style.css"
      
      style_content = Renderers::Css.render_file(@style_path)
      style_destination_directory.mkpath
      style_output_file.open("w+") do |f|
        f << style_content
      end
    end
  end
end