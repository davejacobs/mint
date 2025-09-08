require "pathname"
require "optparse"
require "active_support/core_ext/object/blank"

require_relative "../config"

module Mint
  module Commandline
    # Parses ARGV using OptionParser, mutating ARGV
    #
    # @param [Array] argv a list of arguments to parse
    # @return [Array] a list that contains the command, a help message,
    #   parsed config, and selected scopes
    def self.parse!(argv)
      commandline_options = {}

      parser = OptionParser.new do |cli|
        cli.banner = "Usage: mint [command] files [options]"

        cli.on "-h", "--help", "Show this help message" do
          commandline_options[:help] = true
        end

        cli.on "-v", "--verbose", "Show verbose output" do
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

        cli.on "-o", "--output-file FORMAT", "Specify the output file format with substitutions: \%{name}, \%{original_ext}, \%{ext} (default: \%{name}.\%{ext})" do |o|
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

        cli.on "--no-preserve-structure", "Don't preserve source directory structure in destination" do
          commandline_options[:preserve_structure] = false
        end
        
        cli.on "--navigation", "Make navigation information available to layout, so layout can show a navigation panel (default: false)" do
          commandline_options[:navigation] = true
        end

        cli.on "--no-navigation", "Don't make navigation information available to layout" do
          commandline_options[:navigation] = false
        end
        
        cli.on "--navigation-autodrop", "Automatically drop common directory levels from navigation until multiple top-level nodes exist (default: true)" do
          commandline_options[:navigation_autodrop] = true
        end

        cli.on "--no-navigation-autodrop", "Don't automatically drop common directory levels from navigation" do
          commandline_options[:navigation_autodrop] = false
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
        
        cli.on "--file-title", "Extract title from filename (removes .md extension) and inject into template" do
          commandline_options[:file_title] = true
        end

        cli.on "--no-file-title", "Don't extract title from filename" do
          commandline_options[:file_title] = false
        end
      end

      parser.parse! argv
      command = argv.shift
      
      if argv.include?('-')
        if argv.length > 1
          $stderr.puts "Error: Cannot mix STDIN ('-') with other file arguments"
          exit 1
        end
        
        commandline_options[:files] = [$stdin.read]
        commandline_options[:stdin_mode] = true
      else
        commandline_options[:files] = argv
        commandline_options[:stdin_mode] = false
      end
      
      if commandline_options[:style_mode] == :inline && commandline_options[:style_destination_directory]
        raise ArgumentError, "--style-mode inline and --style-destination cannot be used together"
      end
      
      if commandline_options[:navigation_autodrop] && commandline_options[:navigation_drop] && commandline_options[:navigation_drop] > 0
        raise ArgumentError, "--navigation-autodrop cannot be used with --navigation-drop"
      end
      
      # Process files differently based on whether we're reading from STDIN
      if commandline_options[:stdin_mode]
        files = commandline_options[:files]
      else
        files = commandline_options[:files].map {|f| Pathname.new(f).expand_path }
      end
      
      commandline_config = Config.new(commandline_options)
      config = Config.defaults.merge(Mint.configuration).merge(commandline_config)

      [command, config, files, parser.help]
    end
  end
end