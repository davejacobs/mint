require 'pathname'
require 'yaml'

module Mint
  module Helpers    
    # Transforms a String into a URL-ready slug. Properly handles
    # ampersands, non-alphanumeric characters, extra hyphens and spaces.
    def self.slugize(obj)
      obj.to_s.downcase.
        gsub(/&/, 'and').
        gsub(/[\s-]+/, '-').
        gsub(/[^a-z0-9-]/, '').
        gsub(/[-]+/, '-')
    end

    # Transforms a potentially hyphenated String into a symbol name.
    def self.symbolize(obj)
      slugize(obj).gsub(/-/, '_').to_sym
    end
  
    # Transforms a String or Pathname into a fully expanded Pathname.
    def self.pathize(str_or_path)
      case str_or_path
      when String
        Pathname.new str_or_path
      when Pathname
        str_or_path
      end.expand_path
    end

    # Recursively transforms all keys in a Hash into Symbols.
    def self.symbolize_keys(map)
      map.reduce(Hash.new) do |syms,(k,v)| 
        syms[k.to_sym] = 
          case v
          when Hash
            self.symbolize_keys(v)
          else
            v
          end
        syms
      end
    end

    # Returns the relative path to dir1 from dir2. If dir1 and dir2 
    # have no directories in common besides /, will return the 
    # absolute directory of dir1. Assumes no symlinks.
    def self.normalize_path(dir1, dir2)
      path1, path2 = [dir1, dir2].map {|d| pathize d }
      root1, root2 = [path1, path2].map {|p| p.each_filename.first }
      root1 == root2 ? path1.relative_path_from(path2) : path1
    end

    # Reads Yaml options from file. Updates values with new_opts. Writes
    # merged data back to the same file, overwriting previous data.
    def self.update_yaml(new_opts, file)
      curr_opts = file.exist? ? YAML.load_file(file) : {}

      File.open file, 'w' do |f|
        YAML.dump(curr_opts.merge(new_opts), f)
      end
    end
  end
end
