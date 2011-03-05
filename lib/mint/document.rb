require 'mint/resource'
require 'mint/layout'
require 'mint/style'

module Mint
  class Document < Resource
    # The following provide reader/accessor methods for the objects's
    # important attributes. Each implicit reader is paired with an
    # explicit assignment method that processes a variety of input to a 
    # standardized state.
    
    # When you set content, you are giving the document a renderer based
    # on the content file and are processing the templated content into
    # Html, which you can then access using via the content reader.
    attr_reader :content
    def content=(content)
      @renderer = Mint.renderer content
      @content = @renderer.render
    end

    # The explicit assignment method allows you to pass the document an existing
    # layout or the name of a layout template in the Mint path or an
    # existing layout file.
    attr_reader :layout
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
    
    # The explicit assignment method allows you to pass the document an existing
    # style or the name of a style template in the Mint path or an
    # existing style file.
    attr_reader :style
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

    # I'm going to maintain a document's official style_destination
    # outside of its style object. If a document has no
    # style_destination defined when it needs one, the document will
    # use the style's source directory. This eliminates edge cases
    # nicely and lets us maintain document-specific information
    # separately. (Without this separation, funky things happen when
    # you assign a new style template to an existing document -- if
    # you had specified a custom style_destination before changing
    # the template, that custom destination would be overridden.

    attr_reader :style_destination
    def style_destination=(style_destination)
      @style_destination = style_destination
    end

    def template=(template)
      if template
        self.layout = template
        self.style = template
      end
    end
    
    def initialize(source, opts={})
      options = Mint.default_options.merge opts
      super(source, :document, options)

      # Each of these should invoke explicitly defined method
      self.content  = source
      self.layout   = options[:layout]
      self.style    = options[:style]
      self.style_destination = options[:style_destination]

      # The template option will override layout and style choices
      self.template = options[:template]

      yield self if block_given?
    end

    def render(args={})
      layout.render self, args
    end

    def mint(root=Dir.getwd, render_style=true)      
      root = Pathname.new root
      
      # Only render style if a) it's specified by the options path and
      # b) it actually needs rendering (i.e., it's in template form and
      # not raw, browser-parseable CSS).
      render_style &&= style.needs_rendering?

      document_file = root + (self.destination || '') + self.name
      FileUtils.mkdir_p document_file.dirname
      document_file.open 'w+' do |f|
        f << self.render
      end

      if render_style
        style_dest = 
          if style_destination 
            root + self.destination + style_destination
          else
            self.style.destination
          end
        style_file = style_dest + self.style.name
        FileUtils.mkdir_p style_file.dirname
        
        style_file.open 'w+' do |f|
          f << self.style.render
        end
      end
    end

    # Convenience methods for views

    # Returns a relative path from the document to its stylesheet. Can
    # be called directly from inside a layout template.
    def stylesheet
      style_dest = self.style_destination || self.style.destination
      destination = self.destination || ''
      Helpers.normalize_path(style_dest, destination) + 
        style.name.to_s
    end
  end
end
