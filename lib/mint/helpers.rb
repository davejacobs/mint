require 'pathname'
require 'tempfile'
require 'yaml'
require 'active_support/core_ext/string/inflections'

module Mint
  module Helpers    
    def self.underscore(obj, opts={})
      namespaces = obj.to_s.split('::').map do |namespace|
        if opts[:ignore_prefix]
          namespace[0..1].downcase + namespace[2..-1]
        else
          namespace
        end
      end

      string = opts[:namespaces] ? namespaces.join('::') : namespaces.last
      string.underscore
    end

    # Transforms a String into a URL-ready slug. Properly handles
    # ampersands, non-alphanumeric characters, extra hyphens and spaces.
    #
    # @param [String, #to_s] obj an object to be turned into a slug
    # @return [String] a URL-ready slug
    def self.slugize(obj)
      obj.to_s.downcase.
        gsub(/&/, 'and').
        gsub(/[\s-]+/, '-').
        gsub(/[^a-z0-9-]/, '').
        gsub(/[-]+/, '-')
    end

    # Transforms a potentially hyphenated String into a symbol name.
    #
    # @param [String, #to_s] obj an object to be turned into a symbol name
    # @return [Symbol] a symbol representation of obj
    def self.symbolize(obj)
      slugize(obj).gsub(/-/, '_').to_sym
    end
  
    # Transforms a String or Pathname into a fully expanded Pathname.
    #
    # @param [String, Pathname] str_or_path a path to be expanded
    # @return [Pathname] an expanded representation of str_or_path
    def self.pathize(str_or_path)
      case str_or_path
      when String
        Pathname.new str_or_path
      when Pathname
        str_or_path
      end.expand_path
    end

    # Recursively transforms all keys in a Hash into Symbols.
    #
    # @param [Hash, #[]] map a potentially nested Hash containing symbolizable keys
    # @return [Hash] a version of map where all keys are symbols
    def self.symbolize_keys(map, opts={})
      transform = lambda {|x| opts[:downcase] ? x.downcase : x }

      map.reduce(Hash.new) do |syms,(k,v)| 
        syms[transform[k].to_sym] = 
          case v
          when Hash
            self.symbolize_keys(v, opts)
          else
            v
          end
        syms
      end
    end

    def self.listify(list)
      if list.length > 2
        list[0..-2].join(', ') + ' & ' + list.last
      else
        list.join(' & ')
      end
    end

    def self.standardize(metadata, opts={})
      table = opts[:table] || {}
      metadata.reduce({}) do |hash, (key,value)|
        if table[key] && table[key].length == 2
          standard_key, standard_type = table[key]
          standard_value =
            case standard_type
            when :array
              [*value]
            when :string
              value
            else
              # If key/type were not in table
              value
            end

          hash[standard_key] = standard_value
        else
          hash[key] = value
        end
        hash
      end
    end

    def self.hashify(list1, list2)
      Hash[*list1.zip(list2).flatten]
    end

    # Returns the relative path to to_directory from from_directory. 
    # If to_directory and from_directory have no parents in common besides 
    # /, returns the absolute directory of to_directory. Assumes no symlinks.
    #
    # @param [String, Pathname] to_directory the target directory
    # @param [String, Pathname] from_directory the starting directory
    # @return [Pathname] the relative path to to_directory from 
    #   from_directory, or an absolute path if they have no parents in common
    #   other than /
    def self.normalize_path(to_directory, from_directory)
      to_path, from_path = [to_directory, from_directory].map {|d| pathize d }
      to_root, from_root = [to_path, from_path].map {|p| p.each_filename.first }
      to_root == from_root ? 
        to_path.relative_path_from(from_path) :
        to_path
    end

    # Reads Yaml options from file. Updates values with new_opts. Writes
    # merged data back to the same file, overwriting previous data.
    #
    # @param [Hash, #[]] new_opts a set of options to add to the Yaml file
    # @param [Pathname, #exist] file a file to read from and write to
    # @return [void] 
    def self.update_yaml!(new_opts, file)
      curr_opts = file.exist? ? YAML.load_file(file) : {}

      File.open file, 'w' do |f|
        YAML.dump(curr_opts.merge(new_opts), f)
      end
    end

    def self.generate_temp_file!(file)
      basename  = File.basename file
      extension = File.extname file
      content   = File.read file

      tempfile = Tempfile.new([basename, extension])
      tempfile << content
      tempfile.flush
      tempfile.close
      tempfile.path
    end
  end
end
