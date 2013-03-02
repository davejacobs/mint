require "mint/resource"
require "mint/layout"
require "mint/style"

module Mint
  class Document < Resource
    METADATA_DELIM = "\n\n"

    # Creates a new Mint Document object. Can be block initialized.
    # Accepts source and options. Block initialization occurs after
    # all defaults are set, so not all options must be specified.
    def initialize(source, opts={})
      options = Mint.default_options.merge opts

      # Loads source and destination, which will be used for
      # all source_* and destination_* virtual attributes.
      super(source, options)
      self.type     = :document

      # Each of these should invoke explicitly defined method
      self.content  = source
      self.layout   = options[:layout]
      self.style    = options[:style]
      self.style_destination = options[:style_destination]

      # The template option will override layout and style choices
      self.template = options[:template]

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
      intermediate_content = Plugin.before_render text, {}

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
          layout_file = Mint.lookup_template layout, :layout
          Layout.new layout_file
        end
    rescue TemplateNotFoundException
      abort "Template '#{layout}' does not exist."
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
          style_file = Mint.lookup_template style, :style
          Style.new style_file
        end
    rescue TemplateNotFoundException
      abort "Template '#{style}' does not exist."
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
      Helpers.normalize_path(self.style_destination_file,
                             self.destination_directory).to_s
    end

    def inline_styles
      CSS.parse(metadata)
    end

    # Functions

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
