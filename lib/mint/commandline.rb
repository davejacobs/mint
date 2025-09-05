require "pathname"
require "yaml"
require "optparse"
require "fileutils"
require "shellwords"
require "active_support/core_ext/object/blank"

require_relative "./config"
require_relative "./navigation_processor"

module Mint
  module Commandline
    def self.run!(argv)
      command, help_message, config, files = Mint::Commandline.parse! argv
      case command.to_sym
      when :publish
        Mint::Commandline.publish!(files, config)
      when :help
        Mint::Commandline.help(help_message)
      else
        possible_binary = "mint-#{command}"
        if File.executable? possible_binary
          system "#{possible_binary} #{argv[1..-1].join ' '}"
        else
          $stderr.puts "Error: Unknown command '#{command}'"
          Mint::Commandline.help(help_message)
          exit 1
        end
      end
    end

    # Parses ARGV using OptionParser, mutating ARGV
    #
    # @param [Array] argv a list of arguments to parse
    # @return [Array] a list that contains the command, a help message,
    #   parsed config, and selected scopes
    def self.parse!(argv)
      commandline_options = {}

      parser = OptionParser.new do |cli|
        cli.banner = "Usage: mint [command] files [options]"

        cli.on "-t", "--template TEMPLATE", "Specify a template, which consists of a layout and a style (default: default)" do |t|
          commandline_options[:layout_name] = t
          commandline_options[:style_name] = t
        end

        cli.on "-l", "--layout LAYOUT", "Specify a layout (default: default)" do |l|
          commandline_options[:layout_name] = l
        end

        cli.on "-s", "--style STYLE", "Specify a style (default: default)" do |s|
          commandline_options[:style_name] = s
        end

        cli.on "-w", "--working-dir WORKING_DIR", "Specify a working directory outside the current directory (default: current directory)" do |w|
          commandline_options[:working_directory] = Pathname.new w
        end

        cli.on "-o", "--output-file FORMAT", "Specify the output file format with substitutions: \%{basename}, \%{original_extension}, \%{new_extension} (default: \%{basename}.\%{new_extension})" do |o|
          commandline_options[:output_file_format] = o
        end

        cli.on "-d", "--destination DESTINATION", "Specify a destination directory, relative to the root (default: current directory)" do |d|
          commandline_options[:destination_directory] = Pathname.new d
        end

        cli.on "-m", "--style-mode MODE", ["inline", "external", "original"], "Specify how styles are included (inline, external, original) (default: inline)" do |mode|
          commandline_options[:style_mode] = mode.to_sym
        end

        cli.on "--style-destination DESTINATION", "Create stylesheet in specified directory and link it" do |destination|
          commandline_options[:style_mode] = :external
          commandline_options[:style_destination_directory] = destination
        end

        cli.on "--preserve-structure", "Preserve source directory structure in destination (default: false)" do
          commandline_options[:preserve_structure] = true
        end
        
        cli.on "--navigation", "Make navigation information available to layout, so layout can show a navigation panel (default: false)" do
          commandline_options[:navigation] = true
        end
        
        cli.on "--navigation-drop LEVELS", Integer, "Drop the first N levels of the directory hierarchy from navigation (default: 0)" do |levels|
          commandline_options[:navigation_drop] = levels
        end
        
        cli.on "--navigation-depth DEPTH", Integer, "Maximum depth to show in navigation after dropping levels (default: 3)" do |depth|
          commandline_options[:navigation_depth] = depth
        end
        
        cli.on "--navigation-title TITLE", "Set the title for the navigation panel" do |title|
          commandline_options[:navigation_title] = title
        end
      end

      parser.parse! argv
      command = argv.shift || "help"
      
      
      # MINT_NO_PIPE is used for testing, to convince Mint
      # that STDIN isn't being used
      commandline_options[:files] =
        if $stdin.tty? || ENV["MINT_NO_PIPE"]
          argv
        else
          $stdin.each_line.reduce [] do |list, line|
            list.concat(Shellwords.split(line))
          end
        end
      
      if commandline_options[:style_mode] == :inline && commandline_options[:style_destination_directory]
        raise ArgumentError, "--style-mode inline and --style-destination cannot be used together"
      end
      
      files = commandline_options[:files].map {|f| Pathname.new(f).expand_path }
      commandline_config = Config.new(commandline_options)
      config = Mint.configuration.merge(commandline_config)

      [command, parser.help, config, files]
    end

    # Prints a help banner
    #
    # @param [String, #to_s] message a message to output
    # @return [void]
    def self.help(message)
      puts message
    end
    
    # For each file specified, publishes a new file based on configuration.
    #
    # @param [Array] source_files files a group of filenames
    # @param [Config] config a Config object with all configuration options
    def self.publish!(source_files, config)
      navigation_data = NavigationProcessor.process_navigation_data(source_files, config)
      source_files.each_with_index do |source_file, idx|
        current_file_navigation_data = NavigationProcessor.process_navigation_for_current_file(
          source_file, navigation_data, config
        )
        Mint.publish!(source_file, config, variables: { files: current_file_navigation_data }, render_style: idx == 0)
      end
    end
  end
end
