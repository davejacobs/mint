require "toml"

module Mint
  class Config
    attr_accessor :files
    attr_accessor :stdin_mode
    attr_accessor :stdout_mode
    attr_accessor :help
    attr_accessor :verbose
    attr_accessor :layout_name
    attr_accessor :style_name
    attr_accessor :style_mode
    attr_accessor :output_file_format
    attr_accessor :working_directory            # This can't be set by the user
    attr_accessor :destination_directory
    attr_accessor :style_destination_directory
    attr_accessor :preserve_structure
    attr_accessor :autodrop
    attr_accessor :options
    
    DEFAULT_STDIN_MODE                  = false
    DEFAULT_STDOUT_MODE                 = false
    DEFAULT_VERBOSE                     = false
    DEFAULT_LAYOUT_NAME                 = "default"
    DEFAULT_STYLE_NAME                  = "default"
    DEFAULT_STYLE_MODE                  = :inline
    DEFAULT_OUTPUT_FILE_FORMAT          = '%{name}.%{ext}'
    DEFAULT_WORKING_DIRECTORY           = lambda { Pathname.getwd.expand_path }
    DEFAULT_DESTINATION_DIRECTORY       = lambda { Pathname.getwd.expand_path }
    DEFAULT_PRESERVE_STRUCTURE          = true
    DEFAULT_AUTODROP                    = true
    DEFAULT_OPTIONS                     = {}
    
    def initialize(options = {})
      @stdin_mode = options[:stdin_mode] if options.key?(:stdin_mode)
      @stdout_mode = options[:stdout_mode] if options.key?(:stdout_mode)
      @help = options[:help]
      @verbose = options[:verbose] if options.key?(:verbose)
      @layout_name = options[:layout_name] || options[:template_name]
      @style_name = options[:style_name] || options[:template_name]
      @style_mode = options[:style_mode]
      @output_file_format = options[:output_file_format]
      @working_directory = options[:working_directory]&.expand_path
      @destination_directory = options[:destination_directory]
      @style_destination_directory = options[:style_destination_directory]
      @preserve_structure = options[:preserve_structure] if options.key?(:preserve_structure)
      @autodrop = options[:autodrop] if options.key?(:autodrop)
      @options = options[:options] || {}
    end
    
    def to_h
      {
        stdin_mode: @stdin_mode,
        stdout_mode: @stdout_mode,
        help: @help,
        verbose: @verbose,
        layout_name: @layout_name,
        style_name: @style_name,
        style_mode: @style_mode,
        output_file_format: @output_file_format,
        working_directory: @working_directory,
        destination_directory: @destination_directory,
        style_destination_directory: @style_destination_directory,
        preserve_structure: @preserve_structure,
        autodrop: @autodrop,
        options: @options
      }
    end
    
    def merge(config = Config.new)
      merged_options = to_h.merge(config.to_h.reject {|_, v| v.nil? })

      # Special handling for options - merge the hashes instead of overwriting
      if merged_options[:options] && to_h[:options]
        merged_options[:options] = to_h[:options].merge(merged_options[:options])
      end

      Config.new(merged_options)
    end

    def self.ensure_config(config)
      case config
      when Config
        config
      when Hash
        Config.new(config)
      else
        raise ArgumentError, "config must be a Config object or Hash"
      end
    end
    
    def self.load_file(file)
      toml_config = TOML.load_file(file)
      mapped_config = map_toml_keys_to_config(toml_config) if toml_config.is_a?(Hash)
      Config.new(mapped_config || {})
    end

    def self.defaults
      dest_dir = DEFAULT_DESTINATION_DIRECTORY.call
      Config.new({
        stdin_mode: DEFAULT_STDIN_MODE,
        stdout_mode: DEFAULT_STDOUT_MODE,
        verbose: DEFAULT_VERBOSE,
        layout_name: DEFAULT_LAYOUT_NAME,
        style_name: DEFAULT_STYLE_NAME,
        style_mode: DEFAULT_STYLE_MODE,
        output_file_format: DEFAULT_OUTPUT_FILE_FORMAT,
        working_directory: DEFAULT_WORKING_DIRECTORY.call,
        destination_directory: dest_dir,
        style_destination_directory: Pathname.new('.'),
        preserve_structure: DEFAULT_PRESERVE_STRUCTURE,
        autodrop: DEFAULT_AUTODROP,
        options: DEFAULT_OPTIONS
      })
    end

    def self.with_defaults(overrides = {})
      defaults.merge(new(overrides))
    end

    private

    def self.map_toml_keys_to_config(toml_config)
      mapping = {
        'verbose' => :verbose,
        'template' => :template_name,
        'layout' => :layout_name,
        'style' => :style_name,
        'output-file' => :output_file_format,
        'destination' => :destination_directory,
        'style-mode' => :style_mode,
        'style-destination' => :style_destination_directory,
        'preserve-structure' => :preserve_structure,
        'autodrop' => :autodrop
      }

      mapped = {}
      toml_config.each do |key, value|
        if key == 'options' && value.is_a?(Hash)
          # Handle nested options section
          mapped[:options] = {}
          value.each do |opt_key, opt_value|
            # Convert hyphens to underscores for easier template access
            normalized_key = opt_key.gsub('-', '_').to_sym
            mapped[:options][normalized_key] = opt_value
          end
        else
          mapped_key = mapping[key] || key.to_sym

          # Handle special conversions
          case mapped_key
            when :destination_directory
              mapped[mapped_key] = Pathname.new(value) if value
            when :style_mode
              mapped[mapped_key] = value.to_sym if value
            else
              mapped[mapped_key] = value
            end
        end
      end

      mapped
    end
  end
end
