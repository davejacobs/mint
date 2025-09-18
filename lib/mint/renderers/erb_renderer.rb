require "erb"
require "pathname"

module Mint
  module Renderers
    class Erb
      def self.render(content, variables, layout_path: nil)
        # This context is used to support partials
        context = RenderContext.new(variables, layout_path)
        ERB.new(content).result(context.get_binding)
      end

      class RenderContext
        def initialize(variables = {}, layout_path = nil)
          @layout_path = layout_path
          @layout_dir = layout_path ? Pathname.new(layout_path).dirname : Pathname.new(".")

          variables.each do |key, value|
            instance_variable_set("@#{key}", value)
            define_singleton_method(key) { value }
          end
        end

        def get_binding
          binding
        end

        # Render partial with support for relative paths and locals
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

          # Read and render the partial with merged variables
          partial_content = File.read(partial_path)
          merged_variables = current_variables.merge(locals)

          # Create a new context for the partial with merged variables
          partial_context = RenderContext.new(merged_variables, partial_path.to_s)
          ERB.new(partial_content).result(partial_context.get_binding)
        end

        private

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