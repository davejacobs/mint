require "toml"

module Mint
  class Config
    attr_accessor :help
    attr_accessor :files
    attr_accessor :layout_name
    attr_accessor :style_name
    attr_accessor :style_mode
    attr_accessor :output_file_format
    attr_accessor :working_directory
    attr_accessor :destination_directory
    attr_accessor :style_destination_directory
    attr_accessor :preserve_structure
    attr_accessor :navigation
    attr_accessor :navigation_drop
    attr_accessor :navigation_depth
    attr_accessor :navigation_title
    attr_accessor :file_title
    attr_accessor :verbose
    
    DEFAULT_LAYOUT_NAME                 = "default"
    DEFAULT_STYLE_NAME                  = "default"
    DEFAULT_STYLE_MODE                  = :inline
    DEFAULT_OUTPUT_FILE_FORMAT          = '%{basename}.%{new_extension}'
    DEFAULT_WORKING_DIRECTORY           = lambda { Pathname.getwd }
    DEFAULT_DESTINATION_DIRECTORY       = lambda { Pathname.getwd }
    DEFAULT_PRESERVE_STRUCTURE          = false
    DEFAULT_NAVIGATION                  = false
    DEFAULT_NAVIGATION_DROP             = 0
    DEFAULT_NAVIGATION_DEPTH            = 3
    DEFAULT_FILE_TITLE                  = false
    DEFAULT_VERBOSE                     = false
    
    def initialize(options = {})
      @help = options[:help]
      @layout_name = options[:layout_name] || options[:template_name]
      @style_name = options[:style_name] || options[:template_name]
      @style_mode = options[:style_mode]
      @output_file_format = options[:output_file_format]
      @working_directory = options[:working_directory]
      @destination_directory = options[:destination_directory]
      @style_destination_directory = options[:style_destination_directory] || @destination_directory
      @preserve_structure = options[:preserve_structure] if options.key?(:preserve_structure)
      @navigation = options[:navigation] if options.key?(:navigation)
      @navigation_drop = options[:navigation_drop] if options.key?(:navigation_drop)
      @navigation_depth = options[:navigation_depth] if options.key?(:navigation_depth)
      @navigation_title = options[:navigation_title]
      @file_title = options[:file_title] if options.key?(:file_title)
      @verbose = options[:verbose] if options.key?(:verbose)
    end
    
    def to_h
      {
        help: @help,
        layout_name: @layout_name,
        style_name: @style_name,
        style_mode: @style_mode,
        output_file_format: @output_file_format,
        working_directory: @working_directory,
        destination_directory: @destination_directory,
        style_destination_directory: @style_destination_directory,
        preserve_structure: @preserve_structure,
        navigation: @navigation,
        navigation_drop: @navigation_drop,
        navigation_depth: @navigation_depth,
        navigation_title: @navigation_title,
        file_title: @file_title,
        verbose: @verbose
      }
    end
    
    def merge(config = Config.new)
      Config.new(to_h.merge(config.to_h.reject {|_, v| v.nil? }))
    end
    
    def self.load_file(file)
      toml_config = TOML.load_file(file)
      # Map TOML keys (flag-style) to Config constructor keys
      mapped_config = map_toml_keys_to_config(toml_config) if toml_config.is_a?(Hash)
      Config.new(mapped_config || {})
    end

    def self.defaults
      dest_dir = DEFAULT_DESTINATION_DIRECTORY.call
      Config.new({
        layout_name: DEFAULT_LAYOUT_NAME,
        style_name: DEFAULT_STYLE_NAME,
        style_mode: DEFAULT_STYLE_MODE,
        output_file_format: DEFAULT_OUTPUT_FILE_FORMAT,
        working_directory: DEFAULT_WORKING_DIRECTORY.call,
        destination_directory: dest_dir,
        style_destination_directory: dest_dir,
        preserve_structure: DEFAULT_PRESERVE_STRUCTURE,
        navigation: DEFAULT_NAVIGATION,
        navigation_drop: DEFAULT_NAVIGATION_DROP,
        navigation_depth: DEFAULT_NAVIGATION_DEPTH,
        file_title: DEFAULT_FILE_TITLE,
        verbose: DEFAULT_VERBOSE
      })
    end

    # Helper method for tests to create config with defaults and overrides
    def self.with_defaults(overrides = {})
      defaults.merge(new(overrides))
    end

    private

    def self.map_toml_keys_to_config(toml_config)
      mapping = {
        'template' => :template_name,
        'layout' => :layout_name,
        'style' => :style_name,
        'working-dir' => :working_directory,
        'working_dir' => :working_directory,
        'output-file' => :output_file_format,
        'output_file' => :output_file_format,
        'destination' => :destination_directory,
        'style-mode' => :style_mode,
        'style_mode' => :style_mode,
        'style-destination' => :style_destination_directory,
        'style_destination' => :style_destination_directory,
        'preserve-structure' => :preserve_structure,
        'preserve_structure' => :preserve_structure,
        'navigation' => :navigation,
        'navigation-drop' => :navigation_drop,
        'navigation_drop' => :navigation_drop,
        'navigation-depth' => :navigation_depth,
        'navigation_depth' => :navigation_depth,
        'navigation-title' => :navigation_title,
        'navigation_title' => :navigation_title,
        'file-title' => :file_title,
        'file_title' => :file_title,
        'verbose' => :verbose
      }

      mapped = {}
      toml_config.each do |key, value|
        mapped_key = mapping[key] || key.to_sym
        
        # Handle special conversions
        case mapped_key
        when :working_directory, :destination_directory
          mapped[mapped_key] = Pathname.new(value) if value
        when :style_mode
          mapped[mapped_key] = value.to_sym if value
        else
          mapped[mapped_key] = value
        end
      end
      
      mapped
    end
  end
end
