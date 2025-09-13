require "pathname"

module Mint
  module Helpers
    def self.drop_pathname(pathname, levels_to_drop)
      parts = pathname.to_s.split('/').reject(&:empty?)
      if levels_to_drop >= parts.length
        pathname
      else
        dropped_parts = parts.drop(levels_to_drop)
        if dropped_parts.empty?
          Pathname.new('.')
        else
          Pathname.new(dropped_parts.join('/'))
        end
      end
    end
    
    def self.extract_title_from_file(file_path)
      content = File.read(file_path.to_s)
      
      # Check for Title metadata in Markdown front matter
      if content =~ /^---\n.*?^title:\s*(.+)$/m
        return $1.strip.gsub(/^["']|["']$/, '')
      end
      
      # Check for first markdown heading  
      if content =~ /^#\s+(.+)$/
        return $1.strip
      end
      
      # Fall back to upcased filename with underscores/hyphens converted to spaces
      file_path.basename('.*').to_s.tr('_-', ' ').upcase
    end
  end
end