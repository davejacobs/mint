require "erb"
require "pathname"

module Mint
  module Renderers
    # Enhanced ERB renderer with partial and JavaScript support
    #
    # Provides a robust template rendering system that supports:
    # - ERB template rendering with variable interpolation
    # - Partial template rendering with relative path resolution
    # - Recursive partials for nested structures
    # - JavaScript file inclusion via javascript_tag helper
    #
    # @example Basic usage
    #   Erb.render("<h1><%= title %></h1>", { title: "Hello World" })
    #   #=> "<h1>Hello World</h1>"
    #
    # @example With partials
    #   Erb.render("<%= render 'header' %>", {}, layout_path: "/path/to/layout.erb")
    #
    class Erb
      # Renders an ERB template with the given variables
      #
      # @param content [String] the ERB template content
      # @param variables [Hash] variables to make available in the template
      # @param layout_path [String, nil] path to the layout file for partial resolution
      # @return [String] the rendered template
      #
      # @example
      #   Erb.render("<h1><%= title %></h1>", { title: "My Page" })
      #   #=> "<h1>My Page</h1>"
      def self.render(content, variables, layout_path: nil)
        context = RenderContext.new(variables, layout_path)
        ERB.new(content).result(context.get_binding)
      end

      # Rendering context that provides template helpers and variable access
      #
      # This class creates the execution context for ERB templates, providing:
      # - Access to template variables as methods and instance variables
      # - Helper methods for partial rendering and JavaScript inclusion
      # - Proper binding context for ERB evaluation
      class RenderContext
        # Creates a new rendering context
        #
        # @param variables [Hash] template variables to expose
        # @param layout_path [String, nil] path to layout file for relative partial resolution
        def initialize(variables = {}, layout_path = nil)
          @layout_path = layout_path
          @layout_dir = layout_path ? Pathname.new(layout_path).dirname : Pathname.new(".")

          variables.each do |key, value|
            instance_variable_set("@#{key}", value)
            define_singleton_method(key) { value }
          end
        end

        # Returns the binding for ERB template evaluation
        #
        # @return [Binding] the binding context for template evaluation
        def get_binding
          binding
        end

        # Includes a JavaScript file inline within script tags
        #
        # Reads a JavaScript file from the template directory and wraps it
        # in HTML script tags. If the file doesn't exist, returns an HTML comment.
        #
        # @param js_filename [String] filename of the JavaScript file to include
        # @return [String] HTML script tag with JavaScript content or error comment
        #
        # @example
        #   javascript_tag('navigation.js')
        #   #=> "<script>/* contents of navigation.js */</script>"
        #
        # @example Missing file
        #   javascript_tag('missing.js')
        #   #=> "<!-- JavaScript file not found: /path/to/missing.js -->"
        def javascript_tag(js_filename)
          js_path = @layout_dir + js_filename

          if js_path.exist?
            js_content = File.read(js_path)
            "<script>#{js_content}</script>".html_safe
          else
            "<!-- JavaScript file not found: #{js_path} -->"
          end
        end

        # Renders a partial template with optional local variables
        #
        # Partials are ERB templates that can be included from layouts or other partials.
        # They are resolved relative to the current layout directory and automatically
        # prefixed with underscore if not already present.
        #
        # @param partial_name [String] name of the partial to render (with or without underscore prefix)
        # @param locals [Hash] additional variables to pass to the partial
        # @return [String] the rendered partial content
        # @raise [RuntimeError] if the partial file is not found
        #
        # @example Basic partial
        #   render('header')
        #   # Looks for _header.erb in the template directory
        #
        # @example With locals
        #   render('footer', year: 2024, company: 'ACME Corp')
        #
        # @example Recursive partials
        #   render('navigation_list', files: nested_files)
        def render(partial_name, locals = {})
          if partial_name.start_with?('_')
            partial_file = "#{partial_name}.erb"
          else
            partial_file = "_#{partial_name}.erb"
          end

          partial_path = @layout_dir + partial_file

          unless partial_path.exist?
            raise "Partial not found: #{partial_path}"
          end

          partial_content = File.read(partial_path)
          merged_variables = current_variables.merge(locals)

          partial_context = RenderContext.new(merged_variables, partial_path.to_s)
          ERB.new(partial_content).result(partial_context.get_binding)
        end

        private

        # Extracts current template variables from instance variables
        #
        # @return [Hash] current template variables excluding internal ones
        def current_variables
          variables = {}
          instance_variables.each do |var|
            key = var.to_s.gsub('@', '').to_sym
            next if key == :layout_path || key == :layout_dir
            variables[key] = instance_variable_get(var)
          end
          variables
        end
      end
    end
  end
end