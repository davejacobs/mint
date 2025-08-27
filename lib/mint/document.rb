require "mint/resource"
require "mint/layout"
require "mint/style"

module Mint
  class Document < Resource
    METADATA_DELIM = "\n\n"

    # Creates a new Mint Document object. Can be block initialized.
    # Accepts source and options. Block initialization occurs after
    # all defaults are set, so not all options must be specified.
    def initialize(source, opts = {})
      options = Mint.default_options.merge opts

      preserve_folder_structure!(source, options)
      if options[:all_files] && options[:all_files].any?
        @all_files = options[:all_files]
      end

      # Loads source and destination, which will be used for
      # all source_* and destination_* virtual attributes.
      super(source, options)
      self.type     = :document

      # Each of these should invoke explicitly defined method
      self.content  = source
      self.style_destination = options[:style_destination]

      if options[:layout_or_style_or_template]
        type, name = options[:layout_or_style_or_template]
        case type
        when :template
          self.template = name
        when :layout
          self.layout = name
        when :style
          self.style = name
        end
      end

      self.layout = options[:layout] if options[:layout]
      self.style = options[:style] if options[:style]

      # The template option will override layout and style choices
      self.template = options[:template] if options[:template]

      # Yield self to block after all other parameters are loaded,
      # so we only have to tweak. (We don't have to give up our
      # defaults or re-test blocks beyond them being tweaked.)
      yield self if block_given?
    end

    # Renders content in the context of layout and returns as a String.
    def render(args={})
      intermediate_content = layout.render self, args
      Plugin.after_render(intermediate_content, {})
    end

    # Writes all rendered content where a) possible, b) required,
    # and c) specified. Outputs to specified file.
    def publish!(opts={})
      options = { :render_style => true }.merge(opts)
      super

      # Only renders style if a) it's specified by the options path and
      # b) it actually needs rendering (i.e., it's in template form and
      # not raw, browser-parseable CSS) or it if it doesn't need
      # rendering but there is an explicit style_destination.
      if options[:render_style]
        # Can probably replace this with style.publish! if we can pass in
        # style_destination_directory and style_destination_file
        FileUtils.mkdir_p style_destination_directory
        File.open(self.style_destination_file, "w+") do |f|
          f << self.style.render
        end
      end

      Plugin.after_publish(self, opts)
    end

    # Implicit readers are paired with explicit accessors. This
    # allows for processing variables before storing them.
    attr_reader :metadata, :layout, :style

    # Returns HTML content marked as safe for template rendering
    def content
      @content.html_safe
    end

    # Passes content through a renderer before assigning it to be
    # the Document's content
    #
    # @param [File, #read, #basename] content the content to be rendered
    #   from a templating language into HTML
    # @return [void]
    def content=(content)
      tempfile = Helpers.generate_temp_file! content
      original_content = File.read content

      @metadata, text = Document.parse_metadata_from original_content
      text_with_links = Helpers.transform_markdown_links text
      intermediate_content = Plugin.before_render text_with_links, {}

      File.open(tempfile, "w") do |file|
        file << intermediate_content
      end

      @renderer = Mint.renderer tempfile
      @content = @renderer.render
    end

    # Sets layout to an existing Layout object or looks it up by name
    #
    # @param [String, Layout, #render] layout a Layout object or name
    #   of a layout to be looked up
    # @return [void]
    def layout=(layout)
      @layout =
        if layout.respond_to? :render
          layout
        else
          layout_file = Mint.lookup_layout layout
          Layout.new layout_file
        end
    end

    # Sets layout to an existing Style object or looks it up by name
    #
    # @param [String, Style, #render] layout a Layout object or name
    #   of a layout to be looked up
    # @return [void]
    def style=(style)
      @style =
        if style.respond_to? :render
          style
        else
          style_file = Mint.lookup_style style
          Style.new style_file
        end
    end

    # Overrides layout and style settings with named template.
    #
    # @param [String] template the name of the template to set as
    #   layout and string
    def template=(template)
      if template
        self.layout = template
        self.style = template
      end
    end

    # Explanation of style_destination:
    #
    # I'm going to maintain a document's official style_destination
    # outside of its style object. If a document has no
    # style_destination defined when it needs one, the document will
    # use the original style's source directory.
    #
    # This decision eliminates edge cases, including the case where
    # we want to generate, but not move, a document's style. It also
    # lets us keep style information separate from document-specific
    # information. (Without this separation, funky things happen when
    # you assign a new style template to an existing document -- if
    # you had specified a custom style_destination before changing
    # the template, that custom destination would be overridden.)
    #
    # The style_destination attribute is lazy. It's exposed via
    # virtual attributes like #style_destination_file.
    attr_reader :style_destination

    # @param [String] style_destination the subdirectory into
    #   which styles will be rendered or copied
    # @return [void]
    def style_destination=(style_destination)
      @style_destination = style_destination
    end

    # Exposes style_destination as a Pathname object.
    #
    # @return [Pathname]
    def style_destination_file_path
      if style_destination
        path = Pathname.new style_destination
        dir = path.absolute? ?
          path : destination_directory_path + path
        dir + style.name
      else
        style.destination_file_path
      end
    end

    # Exposes style_destination as a String.
    #
    # @return [String]
    def style_destination_file
      style_destination_file_path.to_s
    end

    # Exposes style_destination directory as a Pathname object.
    #
    # @return [Pathname]
    def style_destination_directory_path
      style_destination_file_path.dirname
    end

    # Exposes style_destination directory as a String.
    #
    # @return [String]
    def style_destination_directory
      style_destination_directory_path.to_s
    end

    # Convenience methods for views

    # Returns a relative path from the document to its stylesheet. Can
    # be called directly from inside a layout template.
    def stylesheet
      tmp_style_dir = Mint.path_for_scope(:user) + "tmp"
      tmp_style_file = tmp_style_dir + File.basename(style.name)
      Helpers.normalize_path(tmp_style_file.to_s,
                             self.destination_directory).to_s
    end

    # Returns the rendered CSS content for inline inclusion
    def inline_stylesheet
      self.style.render
    end

    # Returns either inline CSS or stylesheet link based on rendering mode
    # Use this helper in layouts instead of stylesheet or inline_stylesheet directly
    def stylesheet_tag
      case Mint.rendering_mode
      when :preview
        "<link rel=\"stylesheet\" href=\"#{stylesheet}\">".html_safe
      else
        "<style>#{self.style.render}</style>".html_safe
      end
    end

    # Parses styles defined in YAML metadata in content, including it
    # in output CSS style
    # 
    # TODO: Implement injection of these styles
    def inline_styles
      CSS.parse(metadata)
    end

    # Returns information about all files for navigation in some templates (e.g., garden)
    # Available when processing multiple files
    def files
      return [] unless @all_files
      
      # Get the base directories
      source_base_dir = Pathname.new(root_directory_path).expand_path
      
      # Calculate where the current file will actually be placed
      current_source_path = Pathname.new(source_file_path).expand_path
      current_relative_to_source = current_source_path.relative_path_from(source_base_dir)
      current_html_filename = current_relative_to_source.to_s.gsub(/\.(#{Mint::MARKDOWN_EXTENSIONS.join('|')})$/i, '.html')
      
      dest_base = Pathname.new(root_directory_path).expand_path
      if destination && !destination.empty?
        dest_base = dest_base + destination
      end
      
      current_full_path = dest_base + current_html_filename
      current_destination_dir = current_full_path.dirname
      
      @all_files.map do |file|
        title = extract_title_from_file(file)
        
        # Calculate where this target file will be placed
        file_path = Pathname.new(file).expand_path
        relative_to_source = file_path.relative_path_from(source_base_dir)
        html_filename = relative_to_source.to_s.gsub(/\.(#{Mint::MARKDOWN_EXTENSIONS.join('|')})$/i, '.html')
        
        target_full_path = dest_base + html_filename
        
        # Calculate the relative path from the current file's destination directory to the target file
        relative_link = target_full_path.relative_path_from(current_destination_dir)
        
        {
          source_path: relative_to_source.to_s,
          html_path: relative_link.to_s,
          title: title,
          depth: relative_to_source.to_s.count('/')
        }
      end.sort_by {|f| f[:source_path] }
    end

    # Functions

    private

    # Extracts the title from a markdown file, trying H1 first, then filename
    def extract_title_from_file(file)
      content = File.read(file)
      
      if content =~ /^#\s+(.+)$/
        return $1.strip
      end
      
      File.basename(file, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
    rescue
      File.basename(file, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
    end

    # Preserves folder structure when --recursive is used
    #
    # @param [String] source the source file path
    # @param [Hash] options the options hash to modify
    def preserve_folder_structure!(source, options)
      source_path = Pathname.new(source).expand_path
      root_path = Pathname.new(options[:root] || Dir.getwd).expand_path
      
      relative_path = source_path.relative_path_from(root_path)
      
      relative_dir = relative_path.dirname
      filename = relative_path.basename
      
      # Set destination to preserve directory structure
      if relative_dir.to_s != "."
        # Combine base destination with relative directory structure
        base_destination = options[:destination] || ""
        if base_destination.empty?
          options[:destination] = relative_dir.to_s
        else
          options[:destination] = File.join(base_destination, relative_dir.to_s)
        end
      end
      
      # Set name to HTML version of the markdown file
      options[:name] = filename.sub_ext('.html').to_s
    end

    class << self
      def metadata_chunk(text)
        text.split(METADATA_DELIM).first
      end

      def metadata_from(text)
        raw_metadata = YAML.load metadata_chunk(text)

        case raw_metadata
        when String
          {}
        when false
          {}
        when nil
          {}
        else
          raw_metadata
        end
      rescue Psych::SyntaxError
        {}
      rescue Exception
        {}
      end

      def parse_metadata_from(text)
        metadata = metadata_from text
        new_text =
          if !metadata.empty?
            text.sub metadata_chunk(text) + METADATA_DELIM, ""
          else
            text
          end

        [metadata, new_text]
      end
    end
  end
end
