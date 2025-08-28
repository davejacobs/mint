
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
  ROOT                = (Pathname.new(__FILE__).realpath.dirname + "../..").to_s
  MARKDOWN_EXTENSIONS = %w[md markdown mkd].freeze
  LOCAL_SCOPE         = Pathname.new(".mint")
  USER_SCOPE          = Pathname.new("~/.config/mint").expand_path
  GLOBAL_SCOPE        = Pathname.new("#{ROOT}/config").expand_path
  SCOPES              = { local: LOCAL_SCOPE, user: USER_SCOPE, global: GLOBAL_SCOPE }
  SCOPE_NAMES         = SCOPES.keys
  CONFIG_FILE         = "config.yaml"
  TEMPLATES_DIRECTORY = "templates"

  def self.default_options
    {
      root: Dir.getwd,
      destination: nil,
      style_mode: :inline,
      style_destination: nil,
      output_file: '#{basename}.#{new_extension}',
      layout_or_style_or_template: [:template, 'default'],
      scope: :local,
      recursive: false,
      verbose: false
    }
  end
  
  def self.mapping
    if @mapping
      @mapping
    else
      @mapping = Tilt::Mapping.new.tap do |m|
        m.register Mint::CSSTemplate,       'css'                # Inline Css @imports, creating a single file
        m.register Mint::MarkdownTemplate, 'txt'                # Process Txt as Markdown
        m.register Mint::MarkdownTemplate, *MARKDOWN_EXTENSIONS
        m.register Tilt::ScssTemplate,      'scss'
        m.register Tilt::SassTemplate,      'sass'
        m.register Tilt::ERBTemplate,       'erb', 'html'        # Allow for Erb inside HTML
        m.register Tilt::HamlTemplate,      'haml'
      end
    end
  end

  # Returns an array with the Mint template path for the named scope
  # or scopes. This path is used to lookup templates and configuration options.
  #
  # @param [Array] scopes a list of scopes to include
  # @return [Array] the Mint path as an Array of Pathnames
  def self.path(scopes = SCOPE_NAMES)
    SCOPES.slice(*scopes).values
  end

  # Returns the base directory for Mint configuration at the specified scope.
  #
  # @param [Symbol] scope the scope we want to find the path for
  # @return [Pathname] the Mint path for +scope+ as a Pathname
  def self.path_for_scope(scope = :local)
    SCOPES[scope]
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
    configuration = Mint.path(opts[:scopes]).
      map {|p| p + Mint::CONFIG_FILE }.
      select(&:exist?).
      map do |p| 
        begin
          YAML.load_file p
        rescue Psych::SyntaxError, StandardError => e
          {}
        end
      end.
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
    scopes = if opts[:local] || opts[:user] || opts[:global]
      if opts[:local]
        [:local]
      elsif opts[:user]  
        [:user]
      elsif opts[:global]
        [:global]
      end
    else
      SCOPE_NAMES
    end
    
    processed_opts = opts.dup
    if processed_opts[:layout_or_style_or_template]
      option_type, option_value = processed_opts.delete(:layout_or_style_or_template)
      case option_type
      when :template
        processed_opts[:template] = option_value
      when :layout
        processed_opts[:layout] = option_value
      when :style
        processed_opts[:style] = option_value
      end
    end
    
    configuration(scopes: scopes).merge processed_opts
  end

  # @return [Array] the full path for each known template in the Mint path
  def self.templates(scope = :local)
    Mint.path([scope]).
      map {|p| p + TEMPLATES_DIRECTORY }.
      select(&:exist?).
      map {|p| p.children.select(&:directory?).map(&:to_s) }.
      flatten.
      sort
  end

  # Returns the template directory for the given template name
  #
  # @param [String, File, #to_s] name_or_file a name or template file
  #   to look up
  # @param [Symbol] type the resource type to look up
  # @return [File] the named, typed template file
  def self.lookup_template(name_or_file, type=:layout)
    name = name_or_file.to_s
    
    # Only treat as a direct file if it's an actual file (not directory) 
    if File.file?(name) && formats.include?(File.extname(name)[1..-1])
      Pathname.new(name).dirname
    else
      Pathname.new(find_template_directory(name))
    end
  end

  # Returns the layout file for the given template name or directory
  #
  # @param [String] name the template name or directory path to look up
  # @return [String] path to the layout file
  def self.lookup_layout(name)
    if File.directory?(name)
      find_template_in_directory(name, :layout)
    else
      find_template(name, :layout)
    end
  end

  # Returns the style file for the given template name or directory
  #
  # @param [String] name the template name or directory path to look up
  # @return [String] path to the style file  
  def self.lookup_style(name)
    if File.directory?(name)
      find_template_in_directory(name, :style)
    else
      find_template(name, :style)
    end
  end

  # Finds a template file in a specific directory
  #
  # @param [String] directory_path the directory to look in
  # @param [Symbol] type either :layout or :style
  # @return [String] path to the template file
  def self.find_template_in_directory(directory_path, type)
    acceptable_exts = case type
                      when :layout then formats
                      when :style then css_formats
                      end

    acceptable_exts.each do |ext|
      template_file = File.join(directory_path, "#{type}.#{ext}")
      return template_file if File.exist?(template_file)
    end

    expected_exts = acceptable_exts.join(', ')
    raise TemplateNotFoundException, "Template directory '#{directory_path}' exists but has no valid #{type} file. Expected #{type}.{#{expected_exts}}"
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
    file_name  = lambda {|x| x + Mint::TEMPLATES_DIRECTORY + name + type.to_s }
    find_files = lambda {|x| Pathname.glob "#{x.to_s}.*" }
    acceptable = lambda {|x| 
      ext = File.extname(x.to_s)[1..-1]
      return false unless ext
      case type
      when :layout
        formats.include?(ext)
      when :style  
        css_formats.include?(ext)
      else
        false
      end
    }

    template_file = Mint.path.
      map(&file_name).
      map(&find_files).
      flatten.
      select(&acceptable).
      select(&:exist?).
      first
      
    unless template_file
      template_dirs = Mint.path.map {|p| p + Mint::TEMPLATES_DIRECTORY + name }.select(&:exist?)
      if template_dirs.any?
        expected_exts = case type
                        when :layout then formats.join(', ')
                        when :style then css_formats.join(', ')
                        end
        raise TemplateNotFoundException, "Template '#{name}' exists but has no valid #{type} file. Expected #{type}.{#{expected_exts}}"
      else
        raise TemplateNotFoundException, "Template '#{name}' does not exist."
      end
    end
    
    template_file.to_s
  end

  # Finds a template directory by name
  #
  # @param [String] name the template name to find
  # @return [String] path to the template directory
  def self.find_template_directory(name)
    template_dir = Mint.path.
      map {|p| p + Mint::TEMPLATES_DIRECTORY + name }.
      select(&:exist?).
      first
      
    unless template_dir
      raise TemplateNotFoundException, "Template '#{name}' does not exist."
    end
    
    template_dir.to_s
  end

  # Finds a specific template file by name and type
  #
  # @param [String] name the template name to find
  # @param [Symbol] type :layout or :style
  # @return [String] path to the template file
  def self.find_template_file(name, type)
    find_template(name, type)
  end

  # Returns the template directory for the given scope, if found
  def self.template_path(name, scope)
    Mint.path_for_scope(scope) + "templates/#{name}"
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
