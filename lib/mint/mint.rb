require 'pathname'
require 'fileutils'
require 'yaml'
require 'tilt'

module Mint
  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Scss parser.
  Tilt.register Tilt::ERBTemplate, :html
  Tilt.register Tilt::ScssTemplate, :css

  # @return [String] the Mint root path name
  def self.root
    (Pathname.new(__FILE__).realpath.dirname + '../..').to_s
  end

  # Returns an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  # Either way, earlier/higher paths take precedence. And is considered to
  # be the directory for "local" config options, templates, etc.
  #
  # @param [Boolean] as_path if as_path is true, will return Pathname objects
  # @return [String] the Mint path as a String or Pathname
  def self.path(as_path=false)
    mint_path = ENV['MINT_PATH'] || 
      "#{Dir.getwd}/.mint:~/.mint:#{Mint.root}/config"
    paths = mint_path.split(':')
    as_path ? paths.map {|p| Pathname.new(p).expand_path } : paths
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
      Mint.path(as_path)[index]
    when Hash
      Mint.path(as_path)[scope]
    else
      nil
    end
  end

  # @return [Hash] key Mint directories
  def self.directories
    { 
      templates: 'templates'
    }
  end

  # @return [Hash] key Mint files
  def self.files
    { 
      syntax: 'syntax.yaml',
      defaults: 'defaults.yaml'
    }
  end

  # @return [Hash] last-resort options for creating Mint documents.
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

  # @return [Array] all file extensions that Tilt will render
  def self.formats
    Tilt.mappings.keys
  end

  # @return [Array] CSS formats, for source -> destination
  #   name guessing/conversion only.
  def self.css_formats
    ['css', 'sass', 'scss', 'less']
  end

  # @return [Array] the full path for each known template in the Mint path
  def self.templates
    templates_dir = Mint.directories[:templates]

    Mint.path(true).
      map {|p| p + directories[:templates] }.
      select(&:exist?).
      map {|p| p.children.select(&:directory?).map(&:to_s) }.
      flatten
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
  # will look for `MINT_PATH/templates/layout.*`. If it is :style, will
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
    acceptable = lambda {|x| x.to_s =~ /#{Mint.formats.join '|'}/ }

    Mint.path(true).map(&file_name).map(&find_files).flatten.
      select(&acceptable).select(&:exist?).first.tap do |template|
      raise TemplateNotFoundException unless template
    end.to_s
  end

  def self.template_path(name, type, opts={})
    defaults = { 
      scope: :local,
      ext: { layout: 'haml', style: 'sass' }[type]
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
      file_path.dirname.expand_path.to_s =~ /#{paths.join('|')}/
  end

  # Guesses an appropriate name for the resource output file based on
  # its source file's base name
  #
  # @param [String] name source file name
  # @return [String] probably output file name
  def self.guess_name_from(name)
    name = Pathname(name).basename if name
    css = Mint.css_formats.join '|'
    name.to_s.
      gsub(/\.(#{css})$/, '.css').
      gsub(/(\.[^css]+)$/, '.html')
  end

  # Transforms a path into a template that will render the file specified
  # at that path
  #
  # @param [Path, File, String, #to_s] path the file to render
  def self.renderer(path)
    Tilt.new path.to_s, :smart => true, :ugly => true
  end

  # Publishes a Document object according to its internal specifications.
  #
  # @param [Document] document a Mint document
  # @return [void]
  def self.publish!(document, opts={})
    document.publish! opts
  end
end
