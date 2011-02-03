require 'pathname'
require 'fileutils'
require 'tilt'
require 'helpers'

module Mint

  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Less parser.
  Tilt.register 'html', Tilt::ERBTemplate
  Tilt.register 'css', Tilt::LessTemplate

  def root
    Pathname.new(__FILE__).realpath.dirname + '../..'
  end

  # Return the an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  # Either way, earlier/higher paths take precedence. And is considered to
  # be the directory for "local" config options, templates, etc.
  def self.path
    mint_path = ENV['MINT_PATH'] || "#{Dir.getwd}/.mint:~/.mint:#{MINT_DIR}"
    mint_path.split(':').map {|p| Pathname.new(p).expand_path }
  end

  # I want to refactor this so that Mint.path is always a Hash...
  # should take care of this in the Mint.path=() method.
  # Right now, this is a hack. It assumes a sane MINT_PATH, where the
  # first entry is most local, the second is user-level,
  # and the last entry is most global.
  def self.path_for_scope(scope=:local)
    case Mint.path
    when Array
      index = { local: 0, user: 1, global: 2 }[scope]
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
      # Do not set default `template`--will override style and
      # layout when already specified -- causes tricky bugs
      layout: 'default',     # default layout
      style: 'default',      # default style
      destination: nil,      # do not create a subdirectory
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
    css_formats = ['.css', '.sass', '.scss', '.less']
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

    file_name  = lambda {|x| x + templates_dir + name + type.to_s }
    find_files = lambda {|x| Pathname.glob "#{x.to_s}.*" }
    acceptable = lambda {|x| x.to_s =~ /#{Mint.formats.join '|'}/ }

    Mint.path.
      map(&file_name).map(&find_files).flatten.
      select(&acceptable).select(&:exist?).
      first
  end

  # Guesses an appropriate name for the resource output file based on
  # its source file's base name
  def self.guess_name_from(name)
    css = Mint.css_formats.join '|'
    name.basename.to_s.
      gsub(/(#{css})$/, '.css').
      gsub(/(\.[^css]+)$/, '.html')
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
    
    # I haven't tested this - moved empty string from
    # default options into this method, so that default options
    # can be uniform - i.e., style_destination and destination
    # can each be nil to indicate that any rendering will be
    # done in the same folder the file is already in. I need
    # to make sure that adding the empty string here actually
    # keeps us in the current working directory
    attr_reader :destination
    def destination=(destination)
      @destination = Pathname.new(destination || '')
    end
    
    attr_reader :name
    def name=(name)
      @name = name
    end

    def renderer=(renderer)
      @renderer = renderer
    end

    def initialize(source, type=:resource, options={})
      return nil unless source

      self.source = source
      self.type = type
      self.destination = options[:destination]
      self.name = Mint.guess_name_from source
      self.renderer = Mint.renderer source
    end

    def equal?(other)
      destination + name == other.destination + other.name
    end
    alias_method :==, :equal?

    def render(context=Object.new, args={})
      # see Tilt TEMPLATES.md for more info
      @renderer.render context, args 
    end
  end

  # Layout describes a resource whose type is `:layout`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Layout < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, :layout, opts)
    end
  end

  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, :style, opts)
    end

    def needs_rendering?
      source.extname !~ /\.css$/
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
    def content=(content)
      meta, body = src.split "\n\n"
      @inline_style = YAML.load meta
      @renderer = Mint.renderer body
      @content = @renderer.render
    rescue
      # I want to dry up this part of the code - and maybe look up which
      # error Yaml will throw if it can't parse the first paragraph
      # in the content
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
          Style.new style_file, :destination => destination
        end
    end

    def template=(template)
      layout, style = template, template if template
    end
    
    def initialize(source, opts={})
      options = Mint.default_options.merge opts
      super(source, :document, options)

      # Each of these should invoke explicitly defined method
      self.content  = source
      self.layout   = options[:layout]
      self.style    = options[:style]

      # The template option takes precedence over the other two
      self.template = options[:template]

      self.style.destination = 
        options[:style_destination] || self.style.source.dirname.expand_path
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

      resources = [self]
      resources << style if render_style

      resources.compact.each do |r|
        dest = root + r.destination + r.name
        FileUtils.mkdir_p dest.dirname
        
        dest.open 'w+' do |f|
          f << r.render
        end
      end
    end

    # Convenience methods for views

    # Returns any inline document style that was parsed from the
    # content file, in the header. For use in view where we want
    # document-specific Css modifications.
    def inline_style
      @inline_style
    end

    # Returns a relative path from the document to its stylesheet. Can
    # be called directly from inside a layout template.
    def stylesheet
      Helpers.normalize_path(style.destination.expand_path, destination) + 
        style.name.to_s
    end
  end
end
