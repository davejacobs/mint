require 'pathname'
require 'yaml'
require 'mint'

module Mint
  module CommandLine
    # A map of all options that mint allows by default. Mint will
    # consume these arguments, with optional parameters, from 
    # the commandline. (All other arguments are taken to be
    # filenames.)
    def self.options
      options_file = '../../../config/options.yaml'
      YAML.load_file File.expand_path(options_file, __FILE__)
    end

    def self.configuration
      config_file = Pathname.new(Mint.files[:config])      

      # Merge config options from all config files on the Mint path,
      # where more local options take precedence over more global
      # options
      Mint.path.map {|p| p + config_file }.
        select(&:exist?).
        map {|p| YAML.load_file p }.
        reverse.
        reduce(Mint.default_options) {|r,p| r.merge p }
    end

    def self.configuration_with(opts)
      configuration.merge opts
    end

    def self.help(message)
      puts message
    end

    # Install the listed file to the scope listed, using 
    # local as the default scope.
    # def self.install(file, scope=:local)
    #   directory = path_for_scope(scope)
    #   FileUtils.copy file, directory
    # end


    # If we get the edit command, will retrieve appropriate file
    # (probably a Mint template) and shell out that file to
    # the user's favorite editor.
    def self.edit(name, layout_or_style=:layout)
      file = Mint.lookup_template name, layout_or_style
      
      editor = ENV['EDITOR'] || 'vim'
      system "#{editor} #{file}"
    end

    def self.configure(opts, scope=:local)
      config_directory = Mint.path_for_scope scope
      config_file = config_directory + Mint.files[:config]
      Helpers.ensure_directory config_directory
      Helpers.update_yaml opts, config_file
    end
 

    # Try to set a config option (at the specified scope) per 
    # the user's command.
    def self.set(key, value, scope=:local)
      configure({ key => value }, scope)
    end

    # Display all active configurations, where local 
    # configurations override global ones.
    def self.config
      puts YAML.dump(configuration)
    end
    
    # Renders and writes to file all resources described by a document.
    # Specifically: it renders itself (inside of its own layout) and then
    # renders its style. This method will overwrite any existing content
    # in a document's destination files. The `render_style` option
    # provides an easy way to stop Mint from rendering a style, even
    # if the document's style is not nil.
    def self.mint(files, commandline_options)
      documents = []
      options = configuration_with commandline_options
      
      root = options[:root] || Dir.getwd

      # Eventually render_style should be replaced with file 
      # change detection
      render_style = true
      files.each do |file|
        Document.new(file, options).mint(root, render_style)
        render_style = false
      end
    end
  end
end
