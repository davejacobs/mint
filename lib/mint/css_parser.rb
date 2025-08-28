require "pathname"

module Mint
  # Parses CSS files to extract @import statements and calculate relative paths
  class CssParser
    
    # Extracts @import statements from CSS content
    #
    # @param [String] css_content the CSS content to parse
    # @return [Array<String>] array of imported file paths
    def self.extract_imports(css_content)
      imports = []
      
      # Match @import statements with various formats:
      # @import "file.css";
      # @import 'file.css';
      # @import url("file.css");
      # @import url('file.css');
      css_content.scan(/@import\s+(?:url\()?['"]([^'"]+)['"](?:\))?;?/i) do |match|
        imports << match[0]
      end
      
      imports
    end
    
    # Resolves all CSS files (main + imports) and calculates their paths relative to HTML output
    #
    # @param [String] main_css_path absolute path to the main CSS file
    # @param [String] html_output_path absolute path to the HTML output file
    # @return [Array<String>] array of relative paths from HTML to CSS files
    def self.resolve_css_files(main_css_path, html_output_path)
      css_files = []
      main_css_file = Pathname.new(main_css_path).expand_path
      html_file = Pathname.new(html_output_path).expand_path
      main_css_relative = main_css_file.relative_path_from(html_file.dirname).to_s
      
      return [main_css_relative] unless main_css_file.exist? && main_css_file.extname == '.css'
      
      begin
        css_content = File.read(main_css_path)
        imports = extract_imports(css_content)
        
        # Add imported files first (they should load before the main file)
        imports.each do |import_path|
          import_file = (main_css_file.dirname + import_path).expand_path
          if import_file.exist? && import_file.extname == '.css'
            relative_import = import_file.relative_path_from(html_file.dirname).to_s
            css_files << relative_import
          end
        end
        
        # Add main file last (after its imports)
        css_files << main_css_relative
        
      rescue => e
        # If we can't read the CSS file, just return the main file
        # This allows the system to gracefully handle missing or unreadable files
        css_files = [main_css_relative]
      end
      
      css_files
    end
    
    # Generates HTML link tags for CSS files
    #
    # @param [Array<String>] css_file_paths array of relative paths to CSS files
    # @return [String] HTML link tags
    def self.generate_link_tags(css_file_paths)
      css_file_paths.map do |css_path|
        %Q{<link rel="stylesheet" href="#{css_path}">}
      end.join("\n    ")
    end
  end
end