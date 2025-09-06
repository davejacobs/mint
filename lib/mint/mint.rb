require "pathname"
require "fileutils"
require "yaml"
require "active_support/core_ext/string/output_safety"

require_relative "./config"
require_relative "./helpers"
require_relative "./css_parser"
require_relative "./renderers/css_renderer"
require_relative "./renderers/markdown_renderer"
require_relative "./renderers/erb_renderer"

module Mint
  PROJECT_ROOT        = (Pathname.new(__FILE__).realpath.dirname + "../..").to_s
  METADATA_DELIM      = "\n\n"
  MARKDOWN_EXTENSIONS = ["md", "markdown", "mkd"]
  HTML_EXTENSIONS     = ["html", "erb", "haml"]
  CSS_EXTENSIONS      = ["css", "scss", "sass"]
  CONTENT_EXTENSIONS  = MARKDOWN_EXTENSIONS 
  LAYOUT_EXTENSIONS   = HTML_EXTENSIONS
  STYLE_EXTENSIONS    = CSS_EXTENSIONS
  LOCAL_SCOPE         = Pathname.new(".mint")
  USER_SCOPE          = Pathname.new("~/.config/mint").expand_path
  GLOBAL_SCOPE        = Pathname.new("#{PROJECT_ROOT}/config").expand_path
  SCOPES              = { local: LOCAL_SCOPE, user: USER_SCOPE, global: GLOBAL_SCOPE }
  SCOPE_NAMES         = SCOPES.keys
  PATH                = [LOCAL_SCOPE, USER_SCOPE, GLOBAL_SCOPE]
  CONFIG_FILE         = "config.toml"
  TEMPLATES_DIRECTORY = "templates"

  # Indicates whether the file is a valid stylesheet
  #
  # @param [Pathname] pathname the pathname to check
  # @return [Boolean] true if the file is a valid stylesheet
  def self.is_valid_stylesheet?(pathname)
    CSS_EXTENSIONS.map {|ext| "style.#{ext}" }.include? pathname.basename.to_s
  end
  
  # Indicates whether the file is a valid layout file
  #
  # @param [Pathname] pathname the pathname to check
  # @return [Boolean] true if the file is a valid layout file
  def self.is_valid_layout_file?(pathname)
    HTML_EXTENSIONS.map {|ext| "layout.#{ext}" }.include? pathname.basename.to_s
  end

  # Indicates whether the directory is a valid template directory.
  #
  # @param [Pathname] directory the directory to check
  # @return [Boolean] true if the directory is a valid template directory
  def self.is_template_directory?(directory)
    # Note that typically templates have only a stylesheet, although they can
    # optionally include a layout file. Most templates can get by with the layout
    # provided by the default template, which is automatically used if no layout
    # file is provided in the template directory.
    directory.children.
      select(&:file?).
      select(&method(:is_valid_stylesheet?))
  end
  
  # Returns a hash of all active config, merging global, user, and local
  # scoped config. Local overrides user, which overrides global config.
  #
  # @return [Config] a structured set of configuration options
  def self.configuration
    Mint::PATH.
      reverse.
      map {|p| p + Mint::CONFIG_FILE }.
      select(&:exist?).
      map {|p| Config.load_file p }.
      reduce(Config.defaults) {|agg, cfg| agg.merge cfg }
  end

  # Publishes a Document object according to its internal specifications.
  #
  # @param [Pathname] pathname linking to a Markdown file to be used as document content
  # @param [Config, Hash] config a Config object or Hash with configuration options
  # @param [Hash] variables template variables to pass to the layout
  # @param [Boolean] render_style whether to render the style, ideal for only rendering 
  #   a style for the first file in a group of files
  def self.publish!(source_file, config: Config.new, variables: {}, render_style: true)
    config = case config
             when Config
               config
             when Hash
               Config.new(config)
             else
               raise ArgumentError, "config must be a Config object or Hash"
             end
    
    original_source_content = File.read source_file
    source_metadata, source_text = self.parse_metadata_from original_source_content
    source_text_with_updated_links = Helpers.transform_markdown_links(source_text,
                                                                      output_file_format: config.output_file_format,
                                                                      new_extension: "html")
    source_content = Mint::Renderers::Markdown.render(source_text_with_updated_links)
    
    # Prepare style for inclusion in final layout
    
    stylesheet_tag = nil
    style_source_file = find_style_by_name(config.style_name)

    unless style_source_file
      raise StyleNotFoundException, "Style '#{config.style_name}' does not exist."
    end

    if config.style_mode == :external
      style_destination_directory = config.style_destination_directory
      style_output_file = style_destination_directory + "style.css"

      if render_style
        style_content = Mint::Renderers::Css.render_file(style_source_file)
        style_destination_directory.mkpath
        style_output_file.open("w+") do |f|
          f << style_content
        end
      end
      stylesheet_tag = "<link rel=\"stylesheet\" href=\"#{style_output_file}\">"
    elsif config.style_mode == :original
      # Calculate the destination HTML file path for relative path calculation
      source_path = Pathname.new(source_file)
      destination_directory = config.destination_directory.expand_path(config.working_directory)
      
      if config.preserve_structure
        relative_path = source_path.relative_path_from(config.working_directory) rescue source_path
        destination_file_basename = Helpers.format_output_file(relative_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
        destination_file_path = destination_directory + relative_path.dirname + destination_file_basename
      else
        destination_file_basename = Helpers.format_output_file(source_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
        destination_file_path = destination_directory + destination_file_basename
      end
      
      # Use CssParser to resolve all imports and generate link tags
      css_file_paths = CssParser.resolve_css_files(style_source_file.to_s, destination_file_path.to_s)
      stylesheet_tag = CssParser.generate_link_tags(css_file_paths)
    else
      style_content = Mint::Renderers::Css.render_file(style_source_file)
      stylesheet_tag = "<style>#{style_content}</style>"
    end

    # Prepare final output file content

    layout_source_file = find_layout_by_name(config.layout_name) || find_layout_by_name(Mint::Config::DEFAULT_LAYOUT_NAME)

    unless layout_source_file
      raise LayoutNotFoundException, "Layout '#{config.layout_name}' does not exist."
    end

    # Extract title from filename if --file-title flag is set
    file_title = nil
    if config.file_title
      file_title = File.basename(source_file, '.*').sub(/\.md$/, '')
    end
    
    document_context = variables.merge(
      content: source_content.html_safe, 
      stylesheet_tag: stylesheet_tag,
      metadata: source_metadata || {},
      source_file: source_file,
      working_directory: config.working_directory,
      config: config,
      title: file_title
    )
    
    original_document_content = File.read(layout_source_file)
    document_content = Mint::Renderers::Erb.render(original_document_content, document_context)
    
    destination_directory = config.destination_directory.expand_path(config.working_directory)
    destination_directory.mkpath

    source_path = Pathname.new(source_file)
    
    if config.preserve_structure
      relative_path = source_path.relative_path_from(config.working_directory) rescue source_path
      destination_file_basename = Helpers.format_output_file(relative_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
      destination_file_path = destination_directory + relative_path.dirname + destination_file_basename
      
      # Create intermediate directories
      destination_file_path.dirname.mkpath
    else
      destination_file_basename = Helpers.format_output_file(source_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
      destination_file_path = destination_directory + destination_file_basename
    end
    
    destination_file_path.open("w+") do |f|
      f << document_content
    end
  end
  
  # Finds a template directory by name
  #
  # @param [String] name the template name to find
  # @return [Pathname] path to the template directory
  def self.find_template_directory_by_name(name)
    Mint::PATH.
      map {|p| p + Mint::TEMPLATES_DIRECTORY + name }.
      select(&:exist?).
      first
  end
  
  # Returns the layout file for the given template name
  #
  # @param [String] name the template name or directory path to look up
  # @return [Pathname] path to the layout file
  def self.find_layout_by_name(name)
    find_layout_in_directory find_template_directory_by_name(name)
  end
  
  # Finds the layout file in a specific directory
  #
  # @param [Pathname] directory the directory to look in
  # @return [Pathname] path to the layout file
  def self.find_layout_in_directory(directory)
    directory&.children&.select(&:file?)&.select(&method(:is_valid_layout_file?))&.first
  end

  #
  # @param [String] name the template name to look up
  # @return [Pathname] path to the style file
  def self.find_style_by_name(name)
    find_style_in_directory find_template_directory_by_name(name)
  end

  # Finds the style file in a specific directory
  #
  # @param [Pathname] directory the directory to look in
  # @return [Pathname] path to the style file
  def self.find_style_in_directory(directory)
    directory&.children&.select(&:file?)&.select(&method(:is_valid_stylesheet?))&.first
  end

  # Extracts the title from a markdown file, trying H1 first, then filename
  def self.extract_title_from_file(file)
    content = File.read(file)
    
    if content =~ /^#\s+(.+)$/
      return $1.strip
    end
    
    File.basename(file, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
  rescue
    File.basename(file, '.*').tr('_-', ' ').split.map(&:capitalize).join(' ')
  end
  
  def self.metadata_chunk(text)
    text.split(METADATA_DELIM).first
  end

  def self.metadata_from(text)
    raw_metadata = YAML.load metadata_chunk(text)

    case raw_metadata
    when String
      {}
    when false
      {}
    when nil
      {}
    else
      raw_metadata
    end
  rescue Psych::SyntaxError
    {}
  rescue Exception
    {}
  end

  def self.parse_metadata_from(text)
    metadata = metadata_from text
    new_text =
      if !metadata.empty?
        text.sub metadata_chunk(text) + METADATA_DELIM, ""
      else
        text
      end

    [metadata, new_text]
  end
end
