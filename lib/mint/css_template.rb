require 'tilt/template'

module Mint
  class CSSTemplate < Tilt::Template
    self.default_mime_type = 'text/css'

    def prepare
      @data = data
    end

    def evaluate(scope, locals, &block)
      process_imports(@data, File.dirname(file))
    end

    def process_imports(css_content, base_dir)
      css_content.gsub(/@import\s+["']([^"']+)["'];?/) do |match|
        import_path = $1
        
        # If we find a relative path, resolve it
        if import_path.start_with?('../', './')
          full_path = File.expand_path(import_path, base_dir)
        else
          full_path = File.join(base_dir, import_path)
        end

        full_path += '.css' unless full_path.end_with?('.css')

        if File.exist?(full_path)
          imported_content = File.read(full_path)
          process_imports(imported_content, File.dirname(full_path))
        else
          match
        end
      end
    end
  end
end