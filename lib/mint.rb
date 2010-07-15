require 'pathname'
require 'fileutils'
require 'tilt'
require 'haml'
require 'rdiscount'

require 'helpers'

module Mint
  VERSION = '0.1'

  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Less parser.
  Tilt.register 'html', Tilt::ERBTemplate
  Tilt.register 'css', Tilt::LessTemplate

  def self.formats
    Tilt.mappings.keys
  end

  # Registered CSS formats, for source -> destination
  # name guessing/conversion only. Source files with one of these
  # extensions will be converted to '.css' destination files.
  def self.css_formats
    css_formats = [ '.css', '.sass', '.scss', '.less' ]
  end

  class Resource
    attr_accessor :type, :source, :destination, :name

    def initialize(source, opts={}, &block)
      return nil unless source

      @source = Pathname.new source
      @destination = Pathname.new @opts[:destination] || ''
      @name = @opts[:name] || Resource.guess_from(@source)
      @renderer = Resource.renderer @source

      yield self if block_given?
    end

    def equals?(other)
      destination + name == other.destination + other.name
    end
    alias_method :==, :equals?

    def render(context=Object.new, args={})
      @renderer.render context, args # see Tilt TEMPLATES.md for more info
    end

    protected

    # Guesses an appropriate name for the resource output file based on
    # its source file's base name
    def self.guess_from(name)
      css = Mint.css_formats.join '|'
      name.gsub(/#{css}/, '.css').gsub(/\.[^css]+/, '.html')
    end

    # Transforms a path into a template that will render the file specified
    # at that path
    def self.renderer(path)
      Tilt.new path
    end
  end

  # Layout describes a resource whose type is `:layout`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Layout < Resource
    def initialize(source, opts={})
      @type = :layout
      super
    end
  end

  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts={})
      @type = :style
      super
    end
  end

  class Document < Resource
    include Helpers

    attr_reader :content

    def initialize(source, opts={})
      @type = :document
      super(source, opts) # do not pass block, which would interfere with call

      @content = @renderer.render
      @layout = opts[:layout]
      @style = opts[:style]

      yield self if block_given?
    end

    def render(args={})
      layout.render self, args
    end

    # Convenience methods for views

    # Returns the document's text as HTML
    def content; @content; end

    # Returns a relative path from the document to its stylesheet. Can
    # be called directly from inside a layout template.
    def stylesheet
      normalize_path(style.destination, destination) + style.name.to_s
    end
  end

  class Project
    attr_accessor :root, :documents, :layout, :style

    def initialize(root, opts={})
      @opts = Mint.default_opts.merge opts
      (@opts[:layout], @opts[:style] = t, t) if (t = @opts[:template])

      @root = Pathname.new root
      @documents = []
      @layout = @opts[:layout]
      @style = @opts[:style]
      @destination = @opts[:destination]

      yield self if block_given?
    end

    # Renders and writes to file all resources described by a document.
    # Specifically: it renders itself (inside of its own layout) and then
    # renders its style. This method will overwrite any existing content
    # in a document's destination files. The `render_style` option
    # provides an easy way to stop Mint from rendering a style, even
    # if the document's style is not nil.
    def mint
      style_dest = @root.expand_path + @style.destination + @style.name
      FileUtils.mkdir_p style_dest.dirname
      style_dest.open 'w+' do |f|
        f << @style.render
      end

      @documents.each do |doc|
        # Kernel.puts <<-HERE
        #   Source: #{doc.source.expand_path}
        #   Destination: #{@root.expand_path + doc.destination + doc.name}
        # HERE

        dest = @root.expand_path + doc.destination + doc.name
        FileUtils.mkdir_p dest.dirname
        dest.open 'w+' do |f|
          f << doc.render
        end
      end
    end

    def add(document)
      document.layout = @layout
      document.style = @style

      @documents << doc
    end
    alias_method :<<, :add

    def delete(document)
      @documents.delete document
    end
  end
end
