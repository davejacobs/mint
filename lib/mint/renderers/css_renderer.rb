module Mint
  module Renderers
    class Css
      def self.render_file(css_file)
        self.process(css_file.read, css_file.dirname)
      end
      
      def self.process(css_content, base_dir)
        css_content.gsub(/@import\s+["']([^"']+)["'];?/) do |match|
          import_path = Pathname.new $1
          
          if import_path.relative?
            full_path = import_path.expand_path base_dir
          else
            full_path = base_dir + import_path
          end
  
          if full_path.extname != '.css'
            full_path.rename(full_path.to_s + '.css') 
          end
  
          if full_path.exist?
            imported_content = full_path.read
            self.process(imported_content, full_path.dirname)
          else
            match
          end
        end
      end
    end
  end
end