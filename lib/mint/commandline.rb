require 'pathname'
require 'yaml'
require 'optparse'

module Mint
  module CommandLine
    # Commandline-related helper methods

    # Returns a map of all options that mint allows by default. Mint will
    # consume these arguments, with optional parameters, from 
    # the commandline. (All other arguments are taken to be
    # filenames.)
    #
    # @return [Hash] a structured set of options that the commandline
    #   executable accepts
    def self.options
      options_file = "../../../#{Mint.files[:syntax]}"
      YAML.load_file File.expand_path(options_file, __FILE__)
    end

    # Yields each commandline option specified by options_metadata as
    # a key/value pair to a block. If the option does not take a param, the value
    # will be specified as true.
    #
    # @param [Hash, #[]] options_metadata a structured set of options that the executable 
    #   can use to parse commandline configuration options
    # @return [OptionParser] an object that will parse ARGV when called
    def self.parser(options_metadata=Mint::CommandLine.options)
      optparse = OptionParser.new do |opts|
        opts.banner = 'Usage: mint [command] files [options]'

        Helpers.symbolize_keys(options_metadata).each do |k,v|
          has_param = v[:parameter]

          v[:short] = "-#{v[:short]}"
          v[:long] = "--#{v[:long]}"

          if has_param
            v[:long] << " PARAM"
            opts.on v[:short], v[:long], v[:description] do |p|
              yield k.to_sym, p
            end
          else
            opts.on v[:short], v[:long], v[:description] do
              yield k, true
            end
          end
        end
      end
    end

    # Returns a hash of all active options specified by file (for all scopes).
    # That is, if you specify file as 'config.yaml', this will return the aggregate
    # of all config.yaml-specified options in the Mint path, where more local
    # members of the path take precedence over more global ones.
    #
    # @param [String] file a filename pointing to a Mint configuration file
    # @return [Hash] a structured set of configuration options
    def self.configuration(file=Mint.files[:config])
      return nil unless file
      config_file = Pathname.new file

      # Merge config options from all config files on the Mint path,
      # where more local options take precedence over more global
      # options
      configuration = Mint.path(true).map {|p| p + config_file }.
        select(&:exist?).
        map {|p| YAML.load_file p }.
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
      configuration.merge opts
    end

    # Mint built-in commands
    
    # Prints a help banner
    #
    # @param [String, #to_s] message a message to output
    # @return [void]
    def self.help(message)
      puts message
    end

    # @param [File] file the file to install to the appropriate Mint directory
    # @param [Hash] commandline_options a structured set of options, including 
    #   a scope label that the method will use to choose the appropriate 
    #   installation directory
    # @return [void]
    def self.install(file, commandline_options={})
      commandline_options[:local] = true
      scope = [:global, :user, :local].
        select {|e| commandline_options[e] }.
        first

      directory = Mint.path_for_scope(scope)
      FileUtils.copy file, directory
    end

    # Retrieve named template file (probably a built-in or installed 
    # template) and shell out that file to the user's favorite editor.
    #
    # @param [String] name the name of a layout or style to edit
    # @param [Hash] commandline_options a structured set of options, including 
    #   a layout or style flag that the method will use to choose the appropriate 
    #   file to edit
    # @return [void]
    def self.edit(name, commandline_options)
      layout = commandline_options[:layout]
      style = commandline_options[:style]

      if layout and not style
        layout_or_style = :layout
      elsif style
        layout_or_style = :style
      else
        puts optparse.help
      end

      file = Mint.lookup_template name, layout_or_style
      
      editor = ENV['EDITOR'] || 'vi'
      system "#{editor} #{file}"
    end

    # Updates configuration options persistently in the appropriate scope, 
    # which defaults to local.
    #
    # @param [Hash] opts a structured set of options to set on Mint at the specified 
    #   scope
    # @param [Symbol] scope the scope at which to apply the set of options
    # @return [void]
    def self.configure(opts, scope=:local)
      config_directory = Mint.path_for_scope(scope, true)
      config_file = config_directory + Mint.files[:config]
      Helpers.ensure_directory config_directory
      Helpers.update_yaml opts, config_file
    end

    # Tries to set a config option (at the specified scope) per 
    # the user's command.
    #
    # @param key the key to set
    # @param value the value to set key to
    # @param [Hash, #[]] commandline_options a structured set of options, including 
    #   a scope label that the method will use to choose the appropriate 
    #   scope
    # @return [void]
    def self.set(key, value, commandline_options)
      commandline_options[:local] = true
      scope = [:global, :user, :local].
        select {|e| commandline_options[e] }.
        first

      configure({ key => value }, scope)
    end

    # Displays the sum of all active configurations, where local 
    # configurations override global ones.
    #
    # @return [void]
    def self.config
      puts YAML.dump(configuration)
    end
    
    # Renders and writes to file all resources described by a document.
    # Specifically: it publishes a document, using the document's accessors
    # to determine file placement and naming, and then renders its style. 
    # This method will overwrite any existing content in a document's destination 
    # files. The `render_style` option provides an easy way to stop Mint from 
    # rendering a style, even if the document's style is not nil.
    #
    # @param [Array, #each] files a group of filenames
    # @param [Hash, #[]] commandline_options a structured set of configuration options
    #   that will guide Mint.publish!
    # @return [void]
    def self.mint(files, commandline_options)
      documents = []
      options = configuration_with commandline_options
      
      options[:root] ||= Dir.getwd

      # Eventually render_style should be replaced with file 
      # change detection
      render_style = true
      files.each do |file|
        Document.new(file, options).publish!(render_style)
        render_style = false
      end
    end
  end
end
