require "pathname"
require "set"

module Mint
  # Parses CSS files to extract @import statements and calculate relative paths
  class CssParser
    
    # Extracts @import statements from CSS content
    #
    # @param [String] css_content the CSS content to parse
    # @return [Array<String>] array of imported file paths
    def self.extract_imports(css_content)
      imports = []
      
      # Remove CSS comments first to avoid matching commented @import statements
      # Remove /* ... */ style comments
      css_without_comments = css_content.gsub(/\/\*.*?\*\//m, '')
      
      # Match @import statements with various formats:
      # @import "file.css";
      # @import 'file.css';
      # @import url("file.css");
      # @import url('file.css');
      css_without_comments.scan(/@import\s+(?:url\()?['"]([^'"]+)['"](?:\))?;?/i) do |match|
        imports << match[0]
      end
      
      imports
    end
    
    # Recursively resolves a CSS file and its imports
    #
    # @param [Pathname] css_file absolute path to the CSS file as Pathname
    # @param [Pathname] html_dir directory of the HTML output file as Pathname
    # @param [Set] visited set of already processed files to prevent circular imports
    # @return [Array<String>] array of relative paths from HTML to CSS files
    def self.resolve_css_file_recursive(css_file, html_dir, visited = Set.new)
      css_files = []
      
      # Prevent circular imports
      return css_files if visited.include?(css_file.to_s)
      visited.add(css_file.to_s)
      
      return css_files unless css_file.exist? && css_file.extname == '.css'
      
      begin
        css_content = File.read(css_file)
        imports = extract_imports(css_content)
        
        # Recursively process imported files first (they should load before the file that imports them)
        imports.each do |import_path|
          import_file = (css_file.dirname + import_path).expand_path
          css_files.concat(resolve_css_file_recursive(import_file, html_dir, visited))
        end
        
        # Add this file after its imports
        relative_path = css_file.relative_path_from(html_dir).to_s
        css_files << relative_path unless css_files.include?(relative_path)
        
      rescue => e
        # If we can't read the CSS file, skip it
        # This allows the system to gracefully handle missing or unreadable files
      end
      
      css_files
    end
    
    # Resolves all CSS files (main + imports) and calculates their paths relative to HTML output
    #
    # @param [String] main_css_path absolute path to the main CSS file
    # @param [String] html_output_path absolute path to the HTML output file
    # @return [Array<String>] array of relative paths from HTML to CSS files
    def self.resolve_css_files(main_css_path, html_output_path)
      main_css_file = Pathname.new(main_css_path).expand_path
      html_file = Pathname.new(html_output_path).expand_path
      html_dir = html_file.dirname
      
      # If the file doesn't exist or isn't CSS, return just the relative path
      unless main_css_file.exist? && main_css_file.extname == '.css'
        return [main_css_file.relative_path_from(html_dir).to_s]
      end
      
      # Use recursive resolution
      resolve_css_file_recursive(main_css_file, html_dir)
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