require 'pathname'
require 'fileutils'
require 'yaml'
require 'tilt'

require 'mint/exceptions'

module Mint
  # Assume that someone using an Html template has formatted it
  # in Erb and that a Css stylesheet will pass untouched through
  # a Less parser.
  Tilt.register 'html', Tilt::ERBTemplate
  Tilt.register 'css', Tilt::LessTemplate

  def self.root
    (Pathname.new(__FILE__).realpath.dirname + '../..').to_s
  end

  # Return the an array with the Mint template path. Will first look
  # for MINT_PATH environment variable. Otherwise will use smart defaults.
  # Either way, earlier/higher paths take precedence. And is considered to
  # be the directory for "local" config options, templates, etc.
  def self.path(as_path=false)
    mint_path = ENV['MINT_PATH'] || 
      "#{Dir.getwd}/.mint:~/.mint:#{Mint.root}"
    paths = mint_path.split(':')
    as_path ? paths.map {|p| Pathname.new(p).expand_path } : paths
  end

  # I want to refactor this so that Mint.path is always a Hash...
  # should take care of this in the Mint.path=() method.
  # Right now, this is a hack. It assumes a sane MINT_PATH, where the
  # first entry is most local, the second is user-level,
  # and the last entry is most global.
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
    css_formats = ['css', 'sass', 'scss', 'less']
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
    File.exist?(name) ? name : find_template(name, type)
  end

  # Finds a template named `name` in the Mint path. If `type` is :layout,
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

    template = Mint.path(true).map(&file_name).map(&find_files).flatten.
      select(&acceptable).select(&:exist?).first.to_s
    raise TemplateNotFoundException unless template

    template
  end

  # A non-rigourous check to see if the file is somewhere on the
  # MINT_PATH
  def self.template?(file)
    paths = Mint.path.map {|f| File.expand_path f }
    file_path = Pathname.new(file)
    file_path.exist? and 
      file_path.dirname.expand_path.to_s =~ /#{paths.join('|')}/
  end

  # Guesses an appropriate name for the resource output file based on
  # its source file's base name
  def self.guess_name_from(name)
    name = Pathname(name).basename if name
    css = Mint.css_formats.join '|'
    name.to_s.
      gsub(/\.(#{css})$/, '.css').
      gsub(/(\.[^css]+)$/, '.html')
  end

  # Transforms a path into a template that will render the file specified
  # at that path
  def self.renderer(path)
    Tilt.new path.to_s, :smart => true, :ugly => true
  end
end
