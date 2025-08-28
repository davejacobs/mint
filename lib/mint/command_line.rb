require "pathname"
require "yaml"
require "optparse"
require "fileutils"
require "active_support/core_ext/object/blank"

module Mint
  module CommandLine
    # Parses ARGV using OptionParser
    #
    # @param [Array] argv a list of arguments to parse
    # @return [Hash] an object that contains parsed options, remaining arguments,
    #   and a help message
    def self.parse(argv)
      parsed_options = {}

      parser = OptionParser.new do |cli|
        cli.banner = "Usage: mint [command] files [options]"

        cli.on "-t", "--template TEMPLATE", "Specify the template (layout + style)" do |t|
          parsed_options[:layout_or_style_or_template] = [:template, t]
        end

        cli.on "-l", "--layout LAYOUT", "Specify only the layout" do |l|
          parsed_options[:layout_or_style_or_template] = [:layout, l]
        end

        cli.on "-s", "--style STYLE", "Specify only the style" do |s|
          parsed_options[:layout_or_style_or_template] = [:style, s]
        end

        cli.on "-w", "--root ROOT", "Specify a root outside the current directory" do |r|
          parsed_options[:root] = r
        end

        cli.on "-o", "--output-file FORMAT", "Specify the output file format with substitutions: \#{basename}, \#{original_extension}, \#{new_extension}" do |o|
          parsed_options[:output_file] = o
        end

        cli.on "-d", "--destination DESTINATION", "Specify a destination directory, relative to the root" do |d|
          parsed_options[:destination] = d
        end

        cli.on "--style-mode MODE", ["inline", "external"], "Specify how styles are included (inline, external)" do |mode|
          parsed_options[:style_mode] = mode.to_sym
        end

        cli.on "--style-destination DESTINATION", "Create stylesheet at specified directory or file path and link it" do |destination|
          parsed_options[:style_mode] = :external
          parsed_options[:style_destination] = destination
        end

        cli.on "-g", "--global", "Specify config changes on a global level" do
          parsed_options[:scope] = :global
        end

        cli.on "-u", "--user", "Specify config changes on a user-wide level" do
          parsed_options[:scope] = :user
        end

        cli.on "--local", "Specify config changes on a project-specific level" do
          parsed_options[:scope] = :local
        end

        cli.on "-r", "--recursive", "Recursively find all Markdown files in subdirectories" do
          parsed_options[:recursive] = true
        end
      end

      transient_argv = argv.dup
      parser.parse! transient_argv
      
      if parsed_options[:style_mode] == :inline && parsed_options[:style_destination]
        raise ArgumentError, "--style-mode inline and --style-destination cannot be used together"
      end
      
      default_options = Mint.default_options.merge(destination: Dir.getwd)
      { argv: transient_argv, options: default_options.merge(parsed_options), help: parser.help }
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
    # @param [String] name the template name to install as
    # @param [Symbol] scope the scope at which to install
    # @return [void]
    def self.install(file, name, scope = :local)
      if file.nil?
        raise "[error] No file specified for installation"
      end
      
      filename, ext = file.split "."

      template_name = name || filename
      type = Mint.css_formats.include?(ext) ? :style : :layout
      destination = Mint.template_path(template_name, scope) + "#{type}.#{ext}"
      FileUtils.mkdir_p File.dirname(destination)

      if File.exist? file
        FileUtils.cp file, destination
      else
        raise "[error] No such file: #{file}"
      end
    end

    # Uninstall the named template
    #
    # @param [String] name the name of the template to be uninstalled
    # @param [Symbol] scope the scope from which to uninstall
    # @return [void]
    def self.uninstall(name, scope = :local)
      FileUtils.rm_r Mint.template_path(name, scope)
    end

    # List the installed templates
    #
    # @param [String] filter optional filter pattern
    # @param [Symbol] scope the scope to list templates from
    # @return [void]
    def self.templates(filter = "", scope = :local)
      filter = filter.to_s  # Convert nil to empty string
      Mint.templates(scope).
        grep(Regexp.new(filter)).
        sort.
        each do |template|
          puts "#{File.basename template} [#{template}]"
        end
    end

    # Processes the output file format string with substitutions
    #
    # @param [String] format_string the format string with #{} substitutions
    # @param [String] input_file the original input file path
    # @return [String] the processed output file name
    def self.process_output_format(format_string, input_file)
      basename = File.basename(input_file, ".*")
      original_extension = File.extname(input_file)[1..-1] || ""
      
      # TODO: Remove hardcoded new_extension
      new_extension = "html"
      
      format_string.
        gsub('#{basename}', basename).
        gsub('#{original_extension}', original_extension).
        gsub('#{new_extension}', new_extension)
    end

    # Creates a new template directory and file at the specified scope
    #
    # @param [String] name the name of the template to create
    # @param [Symbol] type the type of template (:layout or :style)
    # @param [Symbol] scope the scope at which to create the template
    # @return [String] the path to the created template file
    def self.create_template(name, type, scope)
      content, ext =
        case type
        when :layout
          [default_layout_content, "erb"]
        when :style
          [default_style_content, "css"]
        else
          abort "Invalid template type: #{type}"
        end
      
      template_dir = Mint.template_path(name, scope)
      file_path = "#{template_dir}/#{type}.#{ext}"
      FileUtils.mkdir_p template_dir
      File.write(file_path, content)
      file_path
    end

    # @return [String] default content for layout templates
    def self.default_layout_content
      <<~LAYOUT_TEMPLATE
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <title>Document</title>
            <% if style %>
              <link rel="stylesheet" href="<%= style %>">
            <% end %>
          </head>
          <body>
            <%= content %>
          </body>
        </html>
      LAYOUT_TEMPLATE
    end

    # @return [String] default content for style templates
    def self.default_style_content
      <<~STYLE_TEMPLATE
        body {
          font-family: -apple-system, 'Segoe UI', Roboto, sans-serif;
          line-height: 1.25;
          max-width: 960px;
          margin: 0 auto;
          padding: 2rem;
          color: #333;
        }

        h1, h2, h3, h4, h5, h6 {
          color: #2c3e50;
        }

        a {
          color: #3498db;
          text-decoration: none;
        }

        a:hover {
          text-decoration: underline;
        }

        code {
          background-color: #f8f9fa;
          padding: 0.2em 0.4em;
          border-radius: 3px;
          font-family: 'Monaco', 'Ubuntu Mono', monospace;
        }
      STYLE_TEMPLATE
    end

    # Retrieve named template file (probably a built-in or installed
    # template) and shell out that file to the user's favorite editor.
    #
    # @param [String] name the name of a template to edit
    # @param [Symbol] type either :layout or :style
    # @param [Symbol] scope the scope at which to look for/create the template
    # @return [void]
    def self.edit(name, type, scope)
      abort "[error] No template specified" if name.nil? || name.empty?

      begin
        file = case type
               when :layout
                 Mint.lookup_layout(name)
               when :style
                 Mint.lookup_style(name)
               else
                 abort "[error] Invalid template type: #{type}. Use :layout or :style"
               end
      rescue Mint::TemplateNotFoundException        
        print "Template '#{name}' does not exist. Create it? [y/N]: "
        response = STDIN.gets.chomp.downcase
        
        if response == 'y' || response == 'yes'
          file = create_template(name, type, scope)
          puts "Created template: #{file}"
        else
          abort "Template creation cancelled."
        end
      end

      editor = ENV["EDITOR"] || "vi"
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
      config_directory = Mint.path_for_scope(scope)
      FileUtils.mkdir_p config_directory
      Helpers.update_yaml! "#{config_directory}/#{Mint::CONFIG_FILE}", opts
    end

    # Tries to set a config option (at the specified scope) per
    # the user's command.
    #
    # @param key the key to set
    # @param value the value to set key to
    # @param scope the scope at which to set the configuration
    # @return [void]
    def self.set(key, value, scope = :local)
      configure({ key => value }, scope)
    end

    # Displays the sum of all active configurations, where local
    # configurations override global ones.
    #
    # @return [void]
    def self.config
      puts YAML.dump(Mint.configuration)
    end

    # Recursively discovers Markdown files in the given directories
    #
    # @param [Array] directories the directories to search
    # @return [Array] an array of markdown file paths
    def self.discover_files_recursively(directories)
      markdown_files = []
      directories.each do |dir|
        if File.file?(dir)
          markdown_files << dir if dir =~ /\.(#{Mint::MARKDOWN_EXTENSIONS.join('|')})$/i
        elsif File.directory?(dir)
          Dir.glob("#{dir}/**/*.{#{Mint::MARKDOWN_EXTENSIONS.join(',')}}", File::FNM_CASEFOLD).each do |file|
            markdown_files << file
          end
        end
      end
      markdown_files.sort
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
      # TODO: Establish commandline defaults in one place
      # TODO: Use `commandline_options` everywhere instead of `options` and `doc_options`
      options = { root: Dir.getwd }.merge(Mint.configuration_with commandline_options)

      if commandline_options[:recursive]
        files = discover_files_recursively(files.empty? ? ["."] : files)
      end

      files.each_with_index do |file, idx|
        # Pass all files list when processing multiple files (for navigation in templates like garden)
        all_files = files.size > 1 ? files : nil
        
        Document.new(file,
          root: options[:root],
          destination: options[:destination],
          context: options[:context],
          name: options[:name],
          style_mode: options[:style_mode],
          style_destination: options[:style_destination],
          layout: options[:layout],
          style: options[:style],
          template: options[:template],
          layout_or_style_or_template: options[:layout_or_style_or_template],
          all_files: all_files
        ).publish!(:render_style => (idx == 0))
      end
    end
  end
end
