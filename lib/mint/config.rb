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
    
    def initialize(options = {})
      @help = options[:help]
      @layout_name = options[:layout_name] || options[:template_name] || DEFAULT_LAYOUT_NAME
      @style_name = options[:style_name] || options[:template_name] || DEFAULT_STYLE_NAME
      @style_mode = options[:style_mode] || DEFAULT_STYLE_MODE
      @output_file_format = options[:output_file_format] || DEFAULT_OUTPUT_FILE_FORMAT
      @working_directory = options[:working_directory] || DEFAULT_WORKING_DIRECTORY.call
      @destination_directory = options[:destination_directory] || DEFAULT_DESTINATION_DIRECTORY.call
      @style_destination_directory = options[:style_destination_directory] || @destination_directory
      @preserve_structure = options.key?(:preserve_structure) ? options[:preserve_structure] : DEFAULT_PRESERVE_STRUCTURE
      @navigation = options.key?(:navigation) ? options[:navigation] : DEFAULT_NAVIGATION
      @navigation_drop = options.key?(:navigation_drop) ? options[:navigation_drop] : DEFAULT_NAVIGATION_DROP
      @navigation_depth = options.key?(:navigation_depth) ? options[:navigation_depth] : DEFAULT_NAVIGATION_DEPTH
      @navigation_title = options[:navigation_title]
      @file_title = options.key?(:file_title) ? options[:file_title] : DEFAULT_FILE_TITLE
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
        file_title: @file_title
      }
    end
    
    def merge(config = Config.new)
      Config.new(to_h.merge(config.to_h.reject {|_, v| v.nil? }))
    end
    
    def self.load_file(file)
      yaml_config = YAML.load_file(file)
      # Convert string keys to symbol keys for the constructor
      symbol_config = yaml_config.transform_keys(&:to_sym) if yaml_config.is_a?(Hash)
      Config.new(symbol_config || {})
    end
  end
end
