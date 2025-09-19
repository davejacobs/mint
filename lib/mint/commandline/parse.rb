require "pathname"
require "optparse"
require "active_support/core_ext/object/blank"

require_relative "../config"

module Mint
  module Commandline
    # Parses ARGV using OptionParser, mutating ARGV
    #
    # @param [Array] argv a list of arguments to parse
    # @return [Array] a list that contains a help message,
    #   parsed config, and selected scopes
    def self.parse!(argv)
      commandline_options = {}
      options = {}

      parser = OptionParser.new do |cli|
        cli.banner = "Usage: mint files [options]"

        cli.on "-h", "--help", "Show this help message" do
          commandline_options[:help] = true
        end

        cli.on "--verbose", "Show verbose output" do
          commandline_options[:verbose] = true
        end

        cli.on "-t", "--template TEMPLATE", "Specify a template by name (default: default)" do |t|
          commandline_options[:layout_name] = t
          commandline_options[:style_name] = t
        end

        cli.on "-l", "--layout LAYOUT", "Specify a layout by name (default: default)" do |l|
          commandline_options[:layout_name] = l
        end

        cli.on "-s", "--style STYLE", "Specify a style by name (default: default)" do |s|
          commandline_options[:style_name] = s
        end

        cli.on "-w", "--working-dir WORKING_DIR", "Specify a working directory outside the current directory (default: current directory)" do |w|
          commandline_options[:working_directory] = Pathname.new w
        end

        cli.on "-o", "--output-file FORMAT", "Specify the output file format with substitutions: \%{name}, \%{original_ext}, \%{ext}, or '-' to output to stdout (default: \%{name}.\%{ext})" do |o|
          if o == "-"
            commandline_options[:stdout_mode] = true
          else
            commandline_options[:output_file_format] = o
          end
        end

        cli.on "-d", "--destination DESTINATION", "Specify a destination directory, relative to the root (default: current directory)" do |d|
          commandline_options[:destination_directory] = Pathname.new d
        end

        cli.on "-m", "--style-mode MODE", ["inline", "external", "original"], "Specify how styles are included (inline, external, original) (default: inline)" do |mode|
          commandline_options[:style_mode] = mode.to_sym
        end

        cli.on "--style-destination DESTINATION", "Create stylesheet in specified directory (relative to --destination) and link it" do |destination|
          commandline_options[:style_mode] = :external
          commandline_options[:style_destination_directory] = destination
        end

        cli.on "--preserve-structure", "Preserve source directory structure in destination (default: true)" do
          commandline_options[:preserve_structure] = true
        end

        cli.on "--no-preserve-structure", "Don't preserve source directory structure in destination" do
          commandline_options[:preserve_structure] = false
        end
        
        cli.on "--autodrop", "Automatically drop common directory levels from output file paths (default: true)" do
          commandline_options[:autodrop] = true
        end

        cli.on "--no-autodrop", "Don't automatically drop common directory levels from output file paths" do
          commandline_options[:autodrop] = false
        end

        cli.on "--opt OPTION", "Set layout option: --opt key or --opt key=value (can be used multiple times). Use --opt no-key to set option to false" do |option|
          if option.start_with?('no-') && option.include?('=')
            raise ArgumentError, "Cannot use no- prefix with value assignment: #{option}. Use --opt no-key (without =value) to negate an option."
          elsif option.start_with?('no-')
            # Handle negated options: --opt no-navigation sets navigation to false
            key = option[3..-1] # Remove 'no-' prefix
            if key.start_with?('no-')
              raise ArgumentError, "Double negation not allowed: #{option}. Use --opt #{key} instead of --opt no-#{key}."
            end
            options[key.gsub('-', '_').to_sym] = false
          elsif option.include?('=')
            key, value = option.split('=', 2)
            # Try to parse the value as an integer, otherwise keep as string
            parsed_value = value.match?(/^\d+$/) ? value.to_i : value
            options[key.gsub('-', '_').to_sym] = parsed_value
          else
            options[option.gsub('-', '_').to_sym] = true
          end
        end
      end

      parser.parse! argv

      if argv.include?('-')
        if argv.length > 1
          $stderr.puts "Error: Cannot mix STDIN ('-') with other file arguments"
          exit 1
        end
        
        commandline_options[:files] = []
        commandline_options[:stdin_mode] = true
        commandline_options[:stdin_content] = $stdin.read

        # Because STDIN will be written to a temporary file, we don't want to preserve structure or autodrop;
        # that filesystem should not be visible to the user.
        commandline_options[:preserve_structure] = false
        commandline_options[:autodrop] = true

      else
        commandline_options[:files] = argv
        commandline_options[:stdin_mode] = false
      end
      
      if commandline_options[:style_mode] == :inline && commandline_options[:style_destination_directory]
        raise ArgumentError, "--style-mode inline and --style-destination cannot be used together"
      end

      # STDOUT mode can only be used with a single file and with --style-mode original or --style-mode inline
      if commandline_options[:stdout_mode]
        if !commandline_options[:stdin_mode] && commandline_options[:files].length > 1
          raise ArgumentError, "--output-file - can only be used with a single file or STDIN"
        end

        style_mode = commandline_options[:style_mode] || Config::DEFAULT_STYLE_MODE
        unless [:inline, :original].include?(style_mode)
          raise ArgumentError, "--output-file - can only be used with --style-mode inline or --style-mode original"
        end
      end
      
      if commandline_options[:stdin_mode]
        files = [commandline_options[:stdin_content]]
      else
        files = commandline_options[:files].map {|f| Pathname.new(f) }
      end
      
      commandline_options[:options] = options

      commandline_config = Config.new(commandline_options)
      config = Config.defaults.merge(Mint.configuration).merge(commandline_config)

      [config, files, parser.help]
    end
  end
end