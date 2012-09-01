require 'pathname'
require 'yaml'
require 'optparse'
require 'fileutils'

require 'active_support/core_ext/object/blank'

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
      options_file = "../../../config/#{Mint.files[:syntax]}"
      YAML.load_file File.expand_path(options_file, __FILE__)
    end

    # Parses ARGV according to the specified or default commandline syntax
    #
    # @param [Array] argv a list of arguments to parse
    # @param [Hash] opts default parsing options (to specify syntax file)
    # @return [Hash] an object that contains parsed options, remaining arguments,
    #   and a help message
    def self.parse(argv, opts={})
      opts = { syntax: options }.merge(opts)
      parsed_options = {}

      parser = OptionParser.new do |cli|
        cli.banner = 'Usage: mint [command] files [options]'

        Helpers.symbolize_keys(opts[:syntax]).each do |k,v|
          has_param = v[:parameter]

          v[:short] = "-#{v[:short]}"
          v[:long] = "--#{v[:long]}"

          if has_param
            v[:long] << " PARAM"
            cli.on v[:short], v[:long], v[:description] do |p|
              parsed_options[k.to_sym] = p
            end
          else
            cli.on v[:short], v[:long], v[:description] do
              parsed_options[k.to_sym] = true
            end
          end
        end
      end

      transient_argv = argv.dup 
      parser.parse! transient_argv
      { argv: transient_argv, options: parsed_options, help: parser.help }
    end

    # Mint built-in commands
    
    # Prints a help banner
    #
    # @param [String, #to_s] message a message to output
    # @return [void]
    def self.help(message)
      puts message
    end

    # Install the named file as a template
    #
    # @param [File] file the file to install to the appropriate Mint directory
    # @param [Hash] commandline_options a structured set of options, including 
    #   a scope label that the method will use to choose the appropriate 
    #   installation directory
    # @return [void]
    def self.install(file, commandline_options={})
      opts = { scope: :local }.merge(commandline_options)
      scope = [:global, :user].
        select {|e| commandline_options[e] }.
        first || :local

      filename, ext = file.split '.'

      name = commandline_options[:template] || filename
      type = Mint.css_formats.include?(ext) ? :style : :layout
      destination = Mint.template_path(name, type, :scope => opts[:scope], :ext => ext) 
      FileUtils.mkdir_p File.expand_path("#{destination}/..")

      if File.exist? file
        FileUtils.copy file, destination
      else
        raise '[error] no such file'
      end
    end

    # Uninstall the named template
    #
    # @param [String] name the name of the template to be uninstalled
    # @param [Hash] commandline_options a structured set of options, including 
    #   a scope label that the method will use to choose the appropriate 
    #   installation directory
    # @return [void]
    def self.uninstall(name, commandline_options={})
      opts = { scope: :local }.merge(commandline_options)
      FileUtils.rm_r Mint.template_path(name, :all, :scope => opts[:scope])
    end

    # List the installed templates
    #
    # @return [void]
    def self.templates(filter=nil, commandline_options={})
      scopes = Mint::SCOPE_NAMES.select do |s|
        commandline_options[s] 
      end.presence || Mint::SCOPE_NAMES

      Mint.templates(:scopes => scopes).
        grep(Regexp.new(filter || "")).
        sort.
        each do |template|
          print File.basename template
          print " [#{template}]" if commandline_options[:verbose]
          puts
        end
    end

    # Retrieve named template file (probably a built-in or installed 
    # template) and shell out that file to the user's favorite editor.
    #
    # @param [String] name the name of a layout or style to edit
    # @param [Hash] commandline_options a structured set of options, including 
    #   a layout or style flag that the method will use to choose the appropriate 
    #   file to edit
    # @return [void]
    def self.edit(name, commandline_options={})
      layout = commandline_options[:layout]
      style = commandline_options[:style]

      # Allow for convenient editing (edit 'default' works just as well
      # as edit :style => 'default')
      if style
        name, layout_or_style = style, :style
      elsif layout
        name, layout_or_style = layout, :layout
      else
        layout_or_style = :style
      end

      abort "[error] no template specified" if name.nil? || name.empty?

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
      FileUtils.mkdir_p config_directory
      Helpers.update_yaml! "#{config_directory}/#{Mint.files[:defaults]}", opts
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
    def self.set(key, value, commandline_options={})
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
      puts YAML.dump(Mint.configuration)
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
    def self.publish!(files, commandline_options={})
      options = { root: Dir.getwd }.merge(Mint.configuration_with commandline_options)
      files.each_with_index do |file, idx|
        Document.new(file, options).publish!(:render_style => (idx == 0))
      end
    end
  end
end
