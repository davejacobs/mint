
require "pathname"
require "fileutils"
require "yaml"
require "tilt"
require "tilt/mapping"
require "active_support/core_ext/hash/slice"
require "active_support/core_ext/string/output_safety"
require "mint/css_template"
require "mint/markdown_template"

module Mint
  ROOT = (Pathname.new(__FILE__).realpath.dirname + "../..").to_s

  # Markdown file extensions supported by Mint
  MARKDOWN_EXTENSIONS = %w[md markdown mkd].freeze

  SCOPES = {
    local:  Pathname.new(".mint"),
    user:   Pathname.new("~/.config/mint").expand_path,
    global: Pathname.new("#{ROOT}/config").expand_path
  }

  SCOPE_NAMES = SCOPES.keys

  @rendering_mode = :publish

  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Scss parser.
  @mapping = Tilt::Mapping.new
  @mapping.register Mint::CSSTemplate,          'css'
  @mapping.register Mint::MarkdownTemplate,     *MARKDOWN_EXTENSIONS
  @mapping.register Mint::MarkdownTemplate,     'txt'
  @mapping.register Tilt::ScssTemplate,         'scss'
  @mapping.register Tilt::SassTemplate,         'sass'
  @mapping.register Tilt::ERBTemplate,          'erb'
  @mapping.register Tilt::HamlTemplate,         'haml'

  def self.mapping
    @mapping
  end

  # @return [String] the Mint root path name
  def self.root
    ROOT
  end
  
  # Returns an array with the Mint template path for the named scope
  # or scopes. This path is used to lookup templates and configuration options.
  #
  # @param [Hash] opts a list of options, including :scopes
  # @return [Array] the Mint path as an Array of Pathnames
  def self.path(opts={})
    opts = { scopes: SCOPE_NAMES }.merge(opts)
    SCOPES.slice(*opts[:scopes]).values
  end

  # Returns the part of Mint.path relevant to scope.
  # I want to refactor this so that Mint.path is always a Hash...
  # should take care of this in the Mint.path=() method.
  # Right now, this is a hack. It assumes a sane MINT_PATH, where the
  # first entry is most local, the second is user-level,
  # and the last entry is most global.
  #
  # @param [Symbol] scope the scope we want to find the path for
  # @param [Boolean] as_path if as_path is true, will return Pathname object
  # @return [String] the Mint path for +scope+ as a String or Pathname
  def self.path_for_scope(scope=:local, as_path=false)
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

  # @return [Hash] key Mint directories
  def self.directories
    {
      templates: "templates"
    }
  end

  # @return [Hash] key Mint files
  def self.files
    {
      syntax: "syntax.yaml",
      defaults: "defaults.yaml"
    }
  end

  # @return [Hash] last-resort options for creating Mint documents.
  def self.default_options
    {
      # Do not set default `template`--will override style and
      # layout when already specified -- causes tricky bugs
      layout: "default",     # default layout
      style: "default",      # default style
      destination: nil,      # do not create a subdirectory
      style_destination: nil # do not copy style to root
    }
  end

  # @return [Array] all file extensions that Tilt will render
  def self.formats
    mapping.template_map.keys
  end

  # @return [Array] CSS formats, for source -> destination
  #   name guessing/conversion only.
  def self.css_formats
    ["css", "sass", "scss", "less"]
  end

  def self.rendering_mode
    @rendering_mode
  end

  def self.rendering_mode=(mode)
    @rendering_mode = mode
  end
  
  # Returns a hash of all active options specified by file (for all scopes).
  # That is, if you specify file as "defaults.yaml", this will return the aggregate
  # of all defaults.yaml-specified options in the Mint path, where more local
  # members of the path take precedence over more global ones.
  #
  # @param [String] file a filename pointing to a Mint configuration file
  # @return [Hash] a structured set of configuration options
  def self.configuration(opts={})
    opts = { scopes: SCOPE_NAMES }.merge(opts)

    # Merge config options from all config files on the Mint path,
    # where more local options take precedence over more global
    # options
    configuration = Mint.path(:scopes => opts[:scopes]).
      map {|p| p + Mint.files[:defaults] }.
      select(&:exist?).
      map {|p| YAML.load_file p }.
      reverse.
      reduce(Mint.default_options) {|r,p| r.merge p }

    Helpers.symbolize_keys configuration
  end

  # Returns all configuration options (as specified by the aggregate
  # of all config files), along with opts, where opts take precedence.
  #
  # @param [Hash] additional options to add to the current configuration
  # @return [Hash] a structured set of configuration options with opts
  #   overriding any options from config files
  def self.configuration_with(opts)
    configuration.merge opts
  end

  # @return [Array] the full path for each known template in the Mint path
  def self.templates(opts={})
    opts = { scopes: SCOPE_NAMES }.merge(opts)
    Mint.path(:scopes => opts[:scopes]).
      map {|p| p + directories[:templates] }.
      select(&:exist?).
      map {|p| p.children.select(&:directory?).map(&:to_s) }.
      flatten.
      sort
  end

  # Decides whether the template specified by `name_or_file` is a real
  # file or the name of a template. If it is a real file, Mint will
  # return a that file. Otherwise, Mint will look for a file with that
  # name in the Mint path. The `type` argument indicates whether the
  # template we are looking for is a layout or a style and will affect
  # which type of template is returned for a given template name. For
  # example, `lookup_template :normal` might return a layout template
  # referring to the file ~/.config/mint/templates/normal/layout.erb.
  # Adding :style as a second argument returns
  # ~/.config/mint/templates/normal/style.css.
  #
  # @param [String, File, #to_s] name_or_file a name or template file
  #   to look up
  # @param [Symbol] type the resource type to look up
  # @return [File] the named, typed template file
  def self.lookup_template(name_or_file, type=:layout)
    name = name_or_file.to_s
    File.exist?(name) ? name : find_template(name, type)
  end

  # Finds a template named `name` in the Mint path. If `type` is :layout,
  # will look for `MINT_PATH/templates/template_name/layout.*`. If it is :style, will
  # look for `MINT_PATH/templates/template_name/style.*`. Mint assumes
  # that a named template will hold only one layout and one style template.
  # It does not know how to decide between style.css and style.less, for
  # example. For predictable results, only include one template file
  # called `layout.*` in the `template_name` directory. Returns nil if
  # it cannot find a template.
  #
  # @param [String, #to_s] name the name of a template to find
  # @param [Symbol] type the resource type to find
  #
  # @return [File] the named, typed template file
  def self.find_template(name, type)
    templates_dir = Mint.directories[:templates]

    file_name  = lambda {|x| x + templates_dir + name + type.to_s }
    find_files = lambda {|x| Pathname.glob "#{x.to_s}.*" }

    Mint.path.
      map(&file_name).
      map(&find_files).
      flatten.
      select(&:exist?).
      first.
      tap {|template| raise TemplateNotFoundException unless template }.
      to_s
  end

  def self.template_path(name, type, opts={})
    defaults = {
      scope: :local,
      ext: { layout: "haml", style: "sass" }[type]
    }
    opts = defaults.merge(opts)
    path = Mint.path_for_scope(opts[:scope])

    case type
    when :layout, :style
      "#{path}/templates/#{name}/#{type}.#{opts[:ext]}"
    when :all
      "#{path}/templates/#{name}"
    end
  end

  # Checks (non-rigorously) to see if the file is somewhere on the
  # MINT_PATH
  #
  # @param [String, File, #to_s] file the file to look up
  # @return [Boolean] true if template file is found in Mint path
  def self.template?(file)
    paths = Mint.path.map {|f| File.expand_path f }
    file_path = Pathname.new(file)
    file_path.exist? and
      file_path.dirname.expand_path.to_s =~ /#{paths.map(&:to_s).join("|")}/
  end

  # Guesses an appropriate name for the resource output file based on
  # its source file's base name
  #
  # @param [String] name source file name
  # @return [String] probably output file name
  def self.guess_name_from(name)
    name = Pathname(name).basename if name
    css = Mint.css_formats.join "|"
    name.to_s.
      gsub(/\.(#{css})$/, ".css").
      gsub(/(\.(?!css).*)$/, ".html")
  end

  # Transforms a path into a template that will render the file specified
  # at that path
  #
  # @param [Path, File, String, #to_s] path the file to render
  def self.renderer(path)
    mapping.new path.to_s
  end

  # Publishes a Document object according to its internal specifications.
  #
  # @param [Document] document a Mint document
  # @return [void]
  def self.publish!(document, opts={})
    document.publish! opts
  end
end
