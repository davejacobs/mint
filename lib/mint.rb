require 'pathname'
require 'fileutils'
require 'tilt'
require 'haml'
require 'rdiscount'

require 'helpers'

module Mint
  VERSION = '0.1.2'

  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Less parser.
  Tilt.register 'html', Tilt::ERBTemplate
  Tilt.register 'css', Tilt::LessTemplate

  # Return the an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  # Either way, earlier/higher paths take precedence.
  def self.path
    path = if(e = ENV['MINT_PATH'])
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
      # Do not set default template or will override style and
      # layout when not desired -- causes tricky bugs
      :layout => 'default', # default layout
      :style => 'default',   # default style
      :destination => '',       # do not create a subdirectory
      :style_destination => nil  # do not create a subdirectory
    }
  end

  def self.formats
    Tilt.mappings.keys
  end

  # Registered Css formats, for source -> destination
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
    File.exist?(name) ? Pathname.new(name) : find_template(name, type)
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

    Mint.path.each do |directory|
      templates_dir = directory + Mint.directories[:templates]
      query = templates_dir + name + type.to_s

      if templates_dir.exist?
        # Mint looks for any file with the appropriate basename
        results = Pathname.glob "#{query}.*"
        results.reject! { |r| r.to_s !~ /#{Mint.formats.join('|')}/ }

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
    name.basename.to_s.gsub(/#{css}/, '.css').gsub(/\.[^css]+/, '.html')
  end

  # Transforms a path into a template that will render the file specified
  # at that path
  def self.renderer(path)
    Tilt.new path.to_s
  end

  class Resource
    attr_accessor :type

    attr_reader :source
    def source=(source)
      @source = Pathname.new(source) if source
    end
    
    attr_reader :destination
    def destination=(destination)
      @destination = Pathname.new(destination) if destination
    end
    
    attr_reader :name
    def name=(name)
      @name = name
    end

    def renderer=(renderer)
      @renderer = renderer
    end

    def initialize(src, options={})
      return nil unless src

      self.source = src
      self.destination = options[:destination]
      self.name = Mint.guess_name_from source
      self.renderer = Mint.renderer source
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
    def initialize(source, opts=Mint.default_options)
      @type = :layout
      super
    end
  end

  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts=Mint.default_options)
      @type = :style
      super
    end

    def needs_rendering?
      source.extname != '.css'
    end
  end

  class Document < Resource
    include Helpers

    # The following provide reader/accessor methods for the objects's
    # important attributes. Each implicit reader is paired with an
    # explicit reader that processes a variety of input to a standardized
    # state.
    
    # When you set content, you are giving the document a renderer based
    # on the content file and are processing the templated content into
    # Html, which you can then access using via the content reader.
    attr_reader :content
    def content=(src)
      @renderer = Mint.renderer(src)
      @content = @renderer.render
    end

    # The explicit accessor allows you to pass the document an existing
    # layout or the name of a layout template in the Mint path or an
    # existing layout file.
    attr_reader :layout
    def layout=(layout)      
      if layout.respond_to? :render
        @layout = layout
      else
        layout_file = Mint.lookup_template layout
        @layout = Layout.new(layout_file)
      end
    end
    
    # The explicit accessor allows you to pass the document an existing
    # style or the name of a style template in the Mint path or an
    # existing style file.
    attr_reader :style
    def style=(style)
      if style.respond_to? :render
        @style = style
      else
        style_file = Mint.lookup_template(style, :style)
        @style = Style.new(style_file, :destination => destination)
      end
    end
    
    def initialize(source, opts={})
      options = Mint.default_options.merge opts

      self.type = :document
      super(source, options) # do not pass block, which would interfere with call

      # The template option takes precedence over the other two
      if templ = options[:template]
        (options[:layout], options[:style] = templ, templ) 
      end

      # Each of these should invoke explicitly defined method
      self.content = source
      self.layout = options[:layout]
      self.style = options[:style]
      self.style.destination = options[:style_destination] || self.style.source.dirname.expand_path
    end

    def render(args={})
      layout.render self, args
    end

    def mint(root_directory=Dir.getwd, render_style=true)      
      root_directory = Pathname.new(root_directory)
      
      # Only render style if a) it's specified by the options path and
      # b) it actually needs rendering (i.e., it's in template form and
      # not raw, browser-parseable CSS).
      render_style &&= style.needs_rendering?
      resources = [self]
      resources << style if render_style

      resources.compact.each do |res|
        dest = root_directory + res.destination + res.name
        FileUtils.mkdir_p dest.dirname
        
        dest.open 'w+' do |file|
          file << res.render
        end
      end
    end

    # Convenience methods for views

    # Returns a relative path from the document to its stylesheet. Can
    # be called directly from inside a layout template.
    def stylesheet
      Helpers.normalize_path(style.destination.expand_path, destination) + style.name.to_s
    end
  end
end
