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
    
    def self.guess_title(file_path, content, metadata = {})
      # Start with filename as base title (lowest precedence)
      title = file_path.basename('.*').to_s.tr('_-', ' ').upcase

      # Override with first H1 from markdown if present (medium precedence)
      if content =~ /^#\s+(.+)$/
        title = $1.strip
      end

      # Override with title from frontmatter metadata if present (highest precedence)
      if metadata[:title]
        title = metadata[:title].to_s.strip
      end

      title
    end
  end
end