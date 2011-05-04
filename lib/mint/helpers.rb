require 'pathname'
require 'yaml'

module Mint
  module Helpers    
    def self.slugize(obj)
      obj.to_s.downcase.
        gsub(/&/, 'and').
        gsub(/[\s-]+/, '-').
        gsub(/[^a-z0-9-]/, '').
        gsub(/[-]+/, '-')
    end

    def self.symbolize(obj)
      slugize(obj).gsub(/-/, '_').to_sym
    end
  
    def self.pathize(str_or_path)
      case str_or_path
      when String
        Pathname.new str_or_path
      when Pathname
        str_or_path
      end.expand_path
    end

    # Returns the relative path to dir1 from dir2. If dir1 and dir2 
    # have no directories in common besides /, will return the 
    # absolute directory of dir1. Right now, assumes no symlinks
    def self.normalize_path(dir1, dir2)
      path1, path2 = [dir1, dir2].map {|d| pathize d }
      root1, root2 = [path1, path2].map {|p| p.each_filename.first }
      root1 == root2 ? path1.relative_path_from(path2) : path1
    end

    def self.update_yaml(new_opts, file)
      curr_opts = file.exist? ? YAML.load_file(file) : {}

      File.open file, 'w' do |f|
        YAML.dump(curr_opts.merge(new_opts), f)
      end
    end
  end
end
