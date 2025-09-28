require "pathname"
require "yaml"
require "active_support/core_ext/string/output_safety"

require_relative "./renderers/markdown_renderer"
require_relative "./renderers/erb_renderer"
require_relative "./renderers/css_renderer"
require_relative "./helpers"
require_relative "./document_tree"

module Mint
  class Document
    METADATA_DELIM = "\n\n"
    
    attr_reader :title, :source_path, :destination_path
    
    # @param [Pathname] working_directory path by which relative links should be resolved
    # @param [Pathname] source_path path to markdown file (relative to working_directory)
    # @param [Pathname] destination_path path to output file (relative to destination_directory_path)
    # @param [Pathname] destination_directory_path path to destination directory
    # @param [Pathname] layout_path path to layout file (relative to working_directory)
    # @param [Pathname] style_path path to style file (relative to working_directory)
    # @param [Pathname] style_destination_path path to style destination file
    # @param [Symbol] style_mode style mode (:inline, :external, :original)
    # @param [Proc] transform_links proc to transform link basenames; yields the basename of the link
    # @param [Boolean] render_style whether to render style
    # @param [Hash] options custom options to pass to layout templates
    def initialize(working_directory: Pathname.new('.'),
                   autodrop_prefix_path: Pathname.new('.'),
                   source_path:,
                   destination_path:,
                   destination_directory_path: Pathname.new('.'),
                   layout_path:,
                   style_path:,
                   style_destination_path: Pathname.new('.'),
                   style_mode:,
                   stdout_mode: false,
                   transform_links: Proc.new,
                   render_style: true,
                   options: {})
      @working_directory = working_directory
      @autodrop_prefix_path = autodrop_prefix_path
      @source_path = source_path
      @destination_path = destination_path
      @destination_directory_path = destination_directory_path
      @layout_path = layout_path
      @style_path = style_path
      @style_destination_path = style_destination_path
      @style_mode = style_mode
      @stdout_mode = stdout_mode
      @transform_links = transform_links
      @render_style = render_style
      @options = options

      # Use the full path for reading the file
      full_source_path = @autodrop_prefix_path + @source_path
      source_content = File.read(full_source_path)
      @metadata, @body = parse_metadata_from(source_content)
      @title = Helpers.guess_title(@source_path, @body, @metadata)
    end

    # Publishes the markdown document to HTML
    # 
    # Reads the markdown source file, transforms links, renders to HTML,
    # applies the layout template, and writes to the destination directory.
    # The destination path is resolved at publish time by combining
    # destination_directory_path + destination_path.
    #
    # @return [Pathname] the destination path relative to working_directory
    def publish!(documents: nil)
      if @style_mode == :external && @render_style
        create_external_stylesheet
      end
    
      # Transform Markdown links, taking output format into account
      body_with_rewritten_links = transform_markdown_links(@body, &@transform_links)
      
      # Render Markdown to HTML
      rendered_content = Renderers::Markdown.render(body_with_rewritten_links)
      
      # Create layout variables, for use in the layout template
      layout_variables = {
        working_directory: @working_directory,
        current_path: @source_path.to_s,
        metadata: @metadata,
        title: @title,
        content: rendered_content.html_safe,
        stylesheet_tag: render_stylesheet_tag(@style_path, @style_mode),
        documents: documents ? generate_document_tree(documents: documents).serialize : [],
        options: @options
      }
      
      # Render the layout using ERB with partial support
      layout_content = File.read(@layout_path)
      rendered_content = Renderers::Erb.render(layout_content, layout_variables, layout_path: @layout_path)
      
      if @stdout_mode
        puts rendered_content
        return "STDOUT"
      else
        full_destination_path = @destination_directory_path.absolute? ?
          @destination_directory_path + @destination_path :
          @working_directory + @destination_directory_path + @destination_path

        full_destination_path.dirname.mkpath
        full_destination_path.open("w+") do |f|
          f << rendered_content
        end

        begin
          full_destination_path.relative_path_from(@working_directory)
        rescue ArgumentError
          full_destination_path
        end
      end
    end
    
    # Transforms Markdown links from .md extensions
    #
    # @param [String] text the Markdown text containing links to Markdown documents
    # @yield [String] block used to transform the basename of each Markdown link found
    # @return [String] the text with transformed links
    def transform_markdown_links(text, &block)
      text.gsub(/(\[([^\]]*)\]\(([^)]*\.md)\))/) do |match|
        link_text = $2
        link_url = $3
        
        # Only transform relative links (not absolute URLs)
        if link_url !~ /^https?:\/\//
          # Preserve directory structure in links
          dirname = File.dirname(link_url)
          basename = File.basename(link_url, ".*")
          
          new_filename = yield basename
          
          new_url = if dirname == "."
            new_filename
          else
            File.join(dirname, new_filename)
          end
          
          "[#{link_text}](#{new_url})"
        else
          match
        end
      end
    end

    # Generates navigation tree data for use in layout templates
    #
    # @return [Array<Hash>] array of navigation items with keys:
    #   - :title (String) - display title for the item
    #   - :html_path (String) - path to the HTML file (for files) or nil (for directories)  
    #   - :source_path (String) - path to the source file relative to working directory
    #   - :depth (Integer) - nesting depth in the tree
    #   - :is_directory (Boolean) - true if this is a directory entry (optional key)
    def generate_document_tree(documents:)
      document_tree = DocumentTree.new(documents)
      document_tree.reorient(@destination_path)
    end

    private
    
    # Calculates the relative path of a target pathname to a reference pathname; this is an
    # extension of Pathname#relative_path_from that handles the case where the reference pathname
    # is a file and the target pathname is a directory. In this case, the relative path should be
    # the target pathname.
    # 
    # @param [Pathname] target_pathname the pathname to calculate the relative path for
    # @param [Pathname] reference_pathname the pathname to use as the reference
    # @return [Pathname] the relative path of the target pathname to the reference pathname
    def calculate_relative_path(target_pathname, reference_pathname)
      # Determine if reference is a file based on extension (since the file may not exist on disk yet)
      reference_is_file = !reference_pathname.extname.empty?
      reference_dir = reference_is_file ? reference_pathname.dirname : reference_pathname
      
      begin
        relative_path = target_pathname.relative_path_from(reference_dir)
        
        # Prepend './' to relative paths that don't start with '../'
        # to make it clear they are relative paths within the same directory tree
        relative_str = relative_path.to_s
        if relative_str.start_with?('../')
          relative_path
        else
          Pathname.new("./#{relative_str}")
        end
      rescue
        target_pathname
      end
    end
    
    def metadata_chunk(text)
      match = text.match(/\A---\n(.*?)\n---\n/m)
      match ? match[1] : ""
    end
    
    def metadata_from(text)
      chunk = metadata_chunk(text)
      return {} if chunk.empty?

      raw_metadata = YAML.safe_load(chunk)

      case raw_metadata
      when String, false, nil
        {}
      when Hash
        raw_metadata.transform_keys do |key|
          key.to_s.downcase.gsub(/\s+/, '_').to_sym
        end
      else
        {}
      end
    rescue Psych::SyntaxError => e
      raise "Invalid YAML in front matter: #{e.message}"
    rescue Exception => e
      raise "Error parsing front matter: #{e.message}"
    end

    # Renders a stylesheet tag (either <style> or <link>) based on the style mode
    # 
    # @param [Pathname] style_path the path to the style file
    # @param [Symbol] style_mode the style mode (:inline, :external, :original)
    # @return [String] the stylesheet tag
    def render_stylesheet_tag(style_path, style_mode)
      return "" unless style_path&.exist?
      
      case style_mode
      when :inline
        "<style>#{Renderers::Css.render_file(style_path)}</style>"
      when :external
        full_destination_path = @destination_directory_path.absolute? ? 
          @destination_directory_path + @destination_path : 
          @working_directory + @destination_directory_path + @destination_path
        absolute_stylesheet_path = external_stylesheet_destination_path
        unless absolute_stylesheet_path.absolute?
          absolute_stylesheet_path = @working_directory + absolute_stylesheet_path
        end
        relative_path_to_stylesheet = absolute_stylesheet_path.relative_path_from(full_destination_path.dirname)
        "<link rel=\"stylesheet\" href=\"#{relative_path_to_stylesheet}\">"
      when :original
        full_destination_path = @destination_directory_path.absolute? ? 
          @destination_directory_path + @destination_path : 
          @working_directory + @destination_directory_path + @destination_path
        absolute_style_path = style_path.absolute? ? style_path : @working_directory + style_path
        relative_path_to_original = absolute_style_path.relative_path_from(full_destination_path.dirname)
        "<link rel=\"stylesheet\" href=\"#{relative_path_to_original}\">"
      else
        style_content = Renderers::Css.render_file(style_path)
        "<style>#{style_content}</style>"
      end
    end
    
    # Returns the destination path for the external stylesheet
    # 
    # @return [Pathname] the destination path for the external stylesheet
    def external_stylesheet_destination_path
      @style_destination_path + "style.css"
    end
    
    # Creates an external stylesheet if the style mode is :external
    def create_external_stylesheet
      return unless @style_mode == :external
      style_output_file = external_stylesheet_destination_path
      style_output_file.dirname.mkpath
      style_output_file.open("w+") do |f|
        f << Renderers::Css.render_file(@style_path)
      end
    end
    
    
    # Parse YAML metadata from markdown content
    #
    # @param [String] text markdown content
    # @return [Array] array of [metadata_hash, content_without_metadata]
    def parse_metadata_from(text)
      metadata = metadata_from(text)
      new_text = if text.match(/\A---\n.*?\n---\n/m)
        text.sub(/\A---\n.*?\n---\n/m, "")
      else
        text
      end

      [metadata, new_text]
    end
  end
end