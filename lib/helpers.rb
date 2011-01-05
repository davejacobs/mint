require 'pathname'
require 'fileutils'
require 'yaml'

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

    def self.ensure_directory(dir)
      FileUtils.mkdir_p dir
    end

    def self.update_yaml(new_opts, file)
      curr_opts = file.exist? ? YAML.load_file(file) : {}

      File.open file, 'w' do |f|
        YAML.dump curr_opts.merge(new_opts), f
      end
    end
  end
end
