require 'pathname'
require 'fileutils'
require 'tilt'
require 'haml'
require 'rdiscount'

require 'helpers'

module Mint
  VERSION = '0.1.1'

  # Return the an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  def self.path
    if e = ENV['MINT_PATH']
      e.split(':').collect { |p| Pathname.new(p).expand_path }
    else
      [
        Pathname.new('.mint'),                    # 1. Project-defined
        Pathname.new(ENV['HOME']) + '.mint',      # 2. User-defined
        Pathname.new(__FILE__).dirname + '..'     # 3. Gemfile-defined
      ].collect! { |p| p.expand_path }
    end
  end

  # Returns a hash with key Mint directories
  def self.directories
    directories = { :templates => 'templates' }
  end

  # Returns a hash with key Mint files
  def self.files
    files = { :config => 'config.yaml' }
  end

  def self.default_options
    default_options = {
      :template => 'default',   # default layout and style
      :destination => ''        # do not create a subdirectory
    }
  end

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

  # Decides whether the template specified by `name_or_file` is a real
  # file or the name of a template. If it is a real file, Mint will
  # return a that file. Otherwise, Mint will look for a file with that
  # name in the Mint path. The `type` argument indicates whether the
  # template we are looking for is a layout or a style and will affect
  # which type of template is returned for a given template name. For
  # example, `lookup_template :normal` might return a layout template
  # referring to the file ~/.mint/templates/normal/layout.erb.
  # Adding :style as a second argument returns
  # ~/.mint/templates/normal/style.css.
  def self.lookup_template(name_or_file, type=:layout)
    name = name_or_file.to_s
    File.file?(name) ? Pathname.new(name) : find_template(name, type)
  end

  # Finds a template named `name` in the Mint path. If `type` # is :layout,
  # will look for `${MINT_PATH}/templates/layout.*`. If it is :style, will
  # look for `${MINT_PATH}/templates/template_name/style.*`. Mint assumes
  # that a named template will hold only one layout and one style template.
  # It does not know how to decide between style.css and style.less, for
  # example. For predictable results, only include one template file
  # called `layout.*` in the `template_name` directory. Returns nil if
  # it cannot find a template.
  def self.find_template(name, type)
    file = nil

    $path.each do |directory|
      templates_dir = directory + Mint.directories[:templates]
      query = templates_dir + name + type.to_s

      if templates_dir.exist?
        # Mint looks for any file with the appropriate basename
        results = Pathname.glob "#{query}.*"
        results.reject! {|r| r.to_s !~ /#{Mint.formats.join('|')}/}

        if results.length > 0
          file = results[0]
          break
        end
      end
    end

    file
  end

  # Guesses an appropriate name for the resource output file based on
  # its source file's base name
  def self.guess_name_from(name)
    css = Mint.css_formats.join '|'
    name.gsub(/#{css}/, '.css').gsub(/\.[^css]+/, '.html')
  end

  # Transforms a path into a template that will render the file specified
  # at that path
  def self.renderer(path)
    Tilt.new path
  end

  class Resource
    attr_accessor :type, :source, :destination, :name

    def initialize(source, opts={}, &block)
      return nil unless source

      @source = Pathname.new source
      @destination = Pathname.new @opts[:destination] ||
        Mint.default_options[:destination]
      @name = @opts[:name]
      @name ||= Mint.guess_name_from(@source.basename) if @source.exist?
      @renderer = Mint.renderer @source

      yield self if block_given?
    end

    def equals?(other)
      destination + name == other.destination + other.name
    end
    alias_method :==, :equals?

    def render(context=Object.new, args={})
      @renderer.render context, args # see Tilt TEMPLATES.md for more info
    end
  end

  # Layout describes a resource whose type is `:layout`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Layout < Resource
    def initialize(source, opts={})
      @type = :layout
      super

      @source = Mint.lookup_template(@source, @type)
    end
  end

  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts={})
      @type = :style
      super

      @source = Mint.lookup_template(@source, @type)
    end
  end

  class Document < Resource
    include Helpers

    attr_reader :content

    def initialize(source, opts={})
      @opts = Mint.default_opts.merge(opts)

      @type = :document
      super(source, opts) # do not pass block, which would interfere with call

      @content = @renderer.render

      style_opts = {
        :destination => @opts[:style_destination],
        :name => @opts[:style_name]
      }

      # If a template is passed as an option, use that for the style
      # and layout. Otherwise, use the default-merged options and
      # instantiate a layout and style from there.
      @opts[:layout], @opts[:style] = templ, templ if (templ = @opts[:template])
      @layout = Layout.new @opts[:layout]
      @style = Style.new @opts[:style], style_opts

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
      return nil unless root
      
      @opts = Mint.default_opts.merge opts
      (@opts[:layout], @opts[:style] = t, t) if (t = @opts[:template])

      @root = Pathname.new root
      @destination = @opts[:destination]
      
      @documents = []
      @layout = @opts[:layout]
      @style = @opts[:style]

      yield self if block_given?
    end

    # Renders and writes to file all resources described by a document.
    # Specifically: it renders itself (inside of its own layout) and then
    # renders its style. This method will overwrite any existing content
    # in a document's destination files. The `render_style` option
    # provides an easy way to stop Mint from rendering a style, even
    # if the document's style is not nil.
    def mint
      style_dest = root.expand_path + style.destination + style.name
      
      FileUtils.mkdir_p style_dest.dirname
      style_dest.open 'w+' do |f|
        f << @style.render
      end

      @documents.each do |doc|
        dest = @root.expand_path + doc.destination + doc.name
        
        FileUtils.mkdir_p dest.dirname
        dest.open 'w+' do |f|
          f << doc.render
        end
      end
    end

    def add(document)
      document.layout = @layout
      document.style = nil

      @documents << doc
    end
    alias_method :<<, :add

    def delete(document)
      @documents.delete document
    end
  end
end
