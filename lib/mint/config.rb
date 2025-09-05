module Mint
  class Config
    attr_accessor :files
    attr_accessor :layout_name
    attr_accessor :style_name
    attr_accessor :style_mode
    attr_accessor :output_file_format
    attr_accessor :working_directory
    attr_accessor :destination_directory
    attr_accessor :style_destination_directory
    attr_accessor :preserve_structure
    attr_accessor :create_index
    attr_accessor :navigation
    
    DEFAULT_LAYOUT_NAME                 = "default"
    DEFAULT_STYLE_NAME                  = "default"
    DEFAULT_STYLE_MODE                  = :inline
    DEFAULT_OUTPUT_FILE_FORMAT          = '%{basename}.%{new_extension}'
    DEFAULT_WORKING_DIRECTORY           = lambda { Pathname.getwd }
    DEFAULT_DESTINATION_DIRECTORY       = lambda { Pathname.getwd }
    DEFAULT_PRESERVE_STRUCTURE          = false
    DEFAULT_CREATE_INDEX                = false
    DEFAULT_NAVIGATION                  = false
    
    def initialize(options = {})
      @layout_name = options[:layout_name] || options[:template_name] || DEFAULT_LAYOUT_NAME
      @style_name = options[:style_name] || options[:template_name] || DEFAULT_STYLE_NAME
      @style_mode = options[:style_mode] || DEFAULT_STYLE_MODE
      @output_file_format = options[:output_file_format] || DEFAULT_OUTPUT_FILE_FORMAT
      @working_directory = options[:working_directory] || DEFAULT_WORKING_DIRECTORY.call
      @destination_directory = options[:destination_directory] || DEFAULT_DESTINATION_DIRECTORY.call
      @style_destination_directory = options[:style_destination_directory] || @destination_directory
      @preserve_structure = options.key?(:preserve_structure) ? options[:preserve_structure] : DEFAULT_PRESERVE_STRUCTURE
      @create_index = options.key?(:create_index) ? options[:create_index] : DEFAULT_CREATE_INDEX
      @navigation = options.key?(:navigation) ? options[:navigation] : DEFAULT_NAVIGATION
    end
    
    def to_h
      {
        layout_name: @layout_name,
        style_name: @style_name,
        style_mode: @style_mode,
        output_file_format: @output_file_format,
        working_directory: @working_directory,
        destination_directory: @destination_directory,
        style_destination_directory: @style_destination_directory,
        preserve_structure: @preserve_structure,
        create_index: @create_index,
        navigation: @navigation
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
