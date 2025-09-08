require "pathname"
require "yaml"
require "active_support/core_ext/string/output_safety"

require_relative "./renderers/markdown_renderer"
require_relative "./renderers/erb_renderer"
require_relative "./renderers/css_renderer"

module Mint
  module Document
    METADATA_DELIM = "\n\n"
    
    # Pure function: paths + variables -> HTML content
    # @param [Pathname] markdown_path path to markdown file
    # @param [Pathname] style_path path to style file  
    # @param [Pathname] layout_path path to layout file
    # @param [Hash] variables variables to pass to layout
    # @param [Hash] options rendering options
    # @return [String] rendered HTML content
    def self.publish!(markdown_path:, style_path: nil, layout_path:, variables: {}, options: {})
      # 1. Read and parse markdown (metadata + content)
      markdown_content = File.read(markdown_path)
      metadata, content_text = parse_metadata_from(markdown_content)
      
      # 2. Transform markdown links based on output format
      output_format = options[:output_file_format] || "%{name}.%{ext}"
      content_with_links = self.transform_markdown_links(content_text, 
        output_file_format: output_format, 
        new_extension: "html"
      )
      
      # 3. Render markdown to HTML
      rendered_content = Renderers::Markdown.render(content_with_links)
      
      # 4. Generate style tag from style_path (or use provided one)
      stylesheet_tag = options[:stylesheet_tag] || render_style_tag(style_path, options[:style_mode] || :inline)
      
      # 5. Merge variables with content/style/metadata
      layout_variables = {
        content: rendered_content.html_safe,
        stylesheet_tag: stylesheet_tag,
        metadata: metadata
      }.merge(variables)
      
      # 6. Render through ERB layout
      layout_content = File.read(layout_path)
      Renderers::Erb.render(layout_content, layout_variables)
    end
    
    # Extract title from markdown file content
    # @param [Pathname] file_path path to markdown file
    # @return [String] extracted title
    def self.extract_title_from_file(file_path)
      content = File.read(file_path)
      
      if content =~ /^#\s+(.+)$/
        return $1.strip
      end
      
      File.basename(file_path, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
    rescue
      File.basename(file_path, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
    end
    
    # Parse YAML metadata from markdown content
    # @param [String] text markdown content
    # @return [Array] array of [metadata_hash, content_without_metadata]
    def self.parse_metadata_from(text)
      metadata = metadata_from(text)
      new_text = if !metadata.empty?
        text.sub(metadata_chunk(text) + METADATA_DELIM, "")
      else
        text
      end
      
      [metadata, new_text]
    end
    
    private
    
        # Transforms Markdown links from .md extensions to .html for cross-linking between documents.
    #
    # @param [String] text the markdown text containing links
    # @return [String] the text with transformed links
    def self.transform_markdown_links(text, output_file_format: "%{name}.%{ext}", new_extension: "html")
      text.gsub(/(\[([^\]]*)\]\(([^)]*\.md)\))/) do |match|
        link_text = $2
        link_url = $3
        
        # Only transform relative links (not absolute URLs)
        if link_url !~ /^https?:\/\//
          # Preserve directory structure in links
          dirname = File.dirname(link_url)
          basename = File.basename(link_url, ".*")
          
          new_filename = output_file_format % {
            name: basename,
            ext: new_extension,
            original_ext: "md"
          }
          
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

    # Resolves the output file path for a source file, handling preserve_structure logic
    #
    # @param [Pathname, String] source_file the source file path
    # @param [Config] config the configuration object containing preserve_structure and other options
    # @return [String] the relative path from destination_directory to the output file
    def self.resolve_output_file_path(source_file, config)
      source_path = Pathname.new(source_file)
      
      if config.preserve_structure
        relative_path = source_path.relative_path_from(config.working_directory) rescue source_path
        destination_file_basename = Workspace.format_output_file(relative_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
        
        if relative_path.dirname.to_s == "."
          destination_file_basename
        else
          File.join(relative_path.dirname.to_s, destination_file_basename)
        end
      else
        Workspace.format_output_file(source_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
      end
    end

    # Creates relative navigation links from one file to another
    #
    # @param [String] from_file_path the path to the file that will contain the link
    # @param [String] to_file_path the path to the file being linked to  
    # @param [Config] config the configuration object
    # @return [Pathname] relative path from from_file to to_file
    def self.relative_link_between_files(from_file_path, to_file_path, config)
      from_output_path = resolve_output_file_path(from_file_path, config)
      to_output_path = resolve_output_file_path(to_file_path, config)
      
      from_pathname = Pathname.new(from_output_path)
      to_pathname = Pathname.new(to_output_path)
      
      # Calculate relative path from the directory containing from_file to to_file
      from_dir = from_pathname.dirname
      to_pathname.relative_path_from(from_dir)
    end

    # Render style tag based on style mode
    def self.render_style_tag(style_path, style_mode)
      return "" unless style_path && style_path.exist?
      
      case style_mode
      when :inline
        style_content = Renderers::Css.render_file(style_path)
        "<style>#{style_content}</style>"
      when :external
        # For external mode, just return link tag (path resolution handled elsewhere)
        %(<link rel="stylesheet" href="style.css">)
      when :original
        # For original mode, return empty (CSS link resolution handled elsewhere)
        ""
      else
        style_content = Renderers::Css.render_file(style_path)
        "<style>#{style_content}</style>"
      end
    end
    
    def self.metadata_chunk(text)
      text.split(METADATA_DELIM).first
    end
    
    def self.metadata_from(text)
      raw_metadata = YAML.load(metadata_chunk(text))
      
      case raw_metadata
      when String, false, nil
        {}
      else
        raw_metadata
      end
    rescue Psych::SyntaxError, Exception
      {}
    end
  end
end