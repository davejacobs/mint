require 'pathname'
require 'fileutils'
require 'tilt'
require 'haml'
require 'rdiscount'

require 'helpers'

module Mint
  VERSION = '0.1.3'
  MINT_DIR = Pathname.new(__FILE__).realpath.dirname + '..'

  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Less parser.
  Tilt.register 'html', Tilt::ERBTemplate
  Tilt.register 'css', Tilt::LessTemplate

  # Return the an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  # Either way, earlier/higher paths take precedence.
  def self.path
    mint_path = ENV['MINT_PATH'] || "#{Dir.getwd}/.mint:~/.mint:#{MINT_DIR}"
    path = mint_path.split(':').map {|p| Pathname.new(p).expand_path }
  end

  # I want to refactor this so that Mint.path is always a Hash...
  # should take care of this in the Mint.path=() method.
  # Right now, this is a hack. It assumes a sane MINT_PATH, where the
  # first entry is most local and the last entry is most global.
  def self.path_for_scope(scope=:local)
    case Mint.path
    when Array
      index = { :local => 0, :user => 1, :global => 2 }[scope]
      Mint.path[index]
      
    when Hash
      Mint.path[scope]

    else
      nil
    end
  end

  # Returns a hash with key Mint directories
  def self.directories
    { templates: 'templates' }
  end

  # Returns a hash with key Mint files
  def self.files
    { config: 'config.yaml' }
  end

  def self.default_options
    {
      # Do not set default `:template`--will override style and
      # layout when already specified -- causes tricky bugs
      layout: 'default',     # default layout
      style: 'default',      # default style
      destination: '',       # do not create a subdirectory
      style_destination: nil # do not copy style to root
    }
  end

  # Returns a list of all file extensions that Tilt will render
  def self.formats
    Tilt.mappings.keys
  end

  # Registered Css formats, for source -> destination
  # name guessing/conversion only.
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
    templates_dir = Mint.directories[:templates]
    acceptable_formats = /#{Mint.formats.join '|'}/

    Mint.path.
      map {|p| p + templates_dir + name + type.to_s }.
      map {|p| Pathname.glob("#{p.to_s}.*") }.
      flatten.
      select {|p| p.to_s =~ acceptable_formats }.
      select(&:exist?).
      first
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
    Tilt.new path.to_s, :smart => true
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

    def equal?(other)
      destination + name == other.destination + other.name
    end
    alias_method :==, :equal?

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
    # explicit assignment method that processes a variety of input to a 
    # standardized state.
    
    # When you set content, you are giving the document a renderer based
    # on the content file and are processing the templated content into
    # Html, which you can then access using via the content reader.
    attr_reader :content
    def content=(src)
      @renderer = Mint.renderer src
      @content = @renderer.render
    end

    # The explicit assignment method allows you to pass the document an existing
    # layout or the name of a layout template in the Mint path or an
    # existing layout file.
    attr_reader :layout
    def layout=(layout)      
      if layout.respond_to? :render
        @layout = layout
      else
        layout_file = Mint.lookup_template layout, :layout
        @layout = Layout.new layout_file
      end
    end
    
    # The explicit assignment method allows you to pass the document an existing
    # style or the name of a style template in the Mint path or an
    # existing style file.
    attr_reader :style
    def style=(style)
      if style.respond_to? :render
        @style = style
      else
        style_file = Mint.lookup_template style, :style
        @style = Style.new style_file, :destination => destination
      end
    end
    
    def initialize(source, opts={})
      options = Mint.default_options.merge opts

      self.type = :document
      super(source, options) # do not pass block, which would interfere with call

      # The template option takes precedence over the other two
      if templ = options[:template]
        options[:layout], options[:style] = templ, templ 
      end

      # Each of these should invoke explicitly defined method
      self.content = source
      self.layout = options[:layout]
      self.style = options[:style]
      self.style.destination = options[:style_destination] || 
        self.style.source.dirname.expand_path
    end

    def render(args={})
      layout.render self, args
    end

    def mint(root_directory=Dir.getwd, render_style=true)      
      root_directory = Pathname.new root_directory
      
      # Only render style if a) it's specified by the options path and
      # b) it actually needs rendering (i.e., it's in template form and
      # not raw, browser-parseable CSS).
      render_style &&= style.needs_rendering?
      resources = [self]

      resources << style if render_style

      # Need to reimplement this so that all edge cases are satsified:
      # - Sass file -> rendered, copied
      # - Sass file -> rendered, not copied
      # - Css file -> copied
      # - Css file -> not copied
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
      Helpers.normalize_path(style.destination.expand_path, destination) + 
        style.name.to_s
    end
  end
end
