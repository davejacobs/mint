require 'pathname'
require 'fileutils'
require 'yaml'

module Mint
  module Helpers    
    def self.pathize(str_or_path)
      case str_or_path
      when String
        Pathname.new str_or_path
      when Pathname
        str_or_path
      end.expand_path
    end

    # Returns the relative path to dir1 from dir2.
    def self.normalize_path(dir1, dir2)
      path1, path2 = [dir1, dir2].map {|d| pathize d }
      path1.relative_path_from path2
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

    def self.slugize(obj)
      obj.to_s.downcase.
        gsub(/&/, 'and').
        gsub(/\s+/, '-').
        gsub(/-+/, '-').
        gsub(/[^a-z0-9-]/, '').
        to_sym
    end

    def self.symbolize(obj)
      obj.slugize.gsub(/-/, '_')
    end
  end
end
