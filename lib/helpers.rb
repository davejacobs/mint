require 'pathname'

module Mint
  module Helpers    
    # Returns the relative path to dir1 from dir2.
    def self.normalize_path(dir1, dir2)
      path = case dir1
        when String
          Pathname.new dir1
        when Pathname
          dir1
        end

      path.expand_path.relative_path_from(dir2.expand_path)
    end
  end
end
