require 'mint/mint'

module Mint
  class Resource
    attr_accessor :type

    attr_reader :name
    def name=(name)
      @name = name
    end

    attr_reader :root
    def root=(root)
      @root = root || Dir.getwd
    end

    def root_directory_path
      root ? Pathname.new(root).expand_path : ''
    end

    def root_directory
      root_directory_path.to_s
    end

    attr_accessor :source

    def source_file_path
      path = Pathname.new(source || '')
      path.absolute? ? 
        path.expand_path : root_directory_path + path
    end

    def source_file
      source_file_path.to_s
    end

    def source_directory_path
      source_file_path.dirname
    end

    def source_directory
      source_directory_path.to_s
    end

    attr_accessor :destination

    def destination_file_path
      root_directory_path + (destination || '') + name
    end

    def destination_file
      destination_file_path.to_s
    end

    def destination_directory_path
      destination_file_path.dirname
    end

    def destination_directory
      destination_directory_path.to_s
    end
    
    def renderer=(renderer)
      @renderer = renderer
    end

    def initialize(source, type=:resource, options={})
      return nil unless source

      self.source = source
      self.type = type
      self.name = Mint.guess_name_from source
      self.root = options[:root]
      self.destination = options[:destination]
      self.renderer = Mint.renderer source
    end

    def equal?(other)
      self.destination_file_path == other.destination_file_path
    end
    alias_method :==, :equal?

    def render(context=Object.new, args={})
      # see Tilt TEMPLATES.md for more info
      @renderer.render context, args 
    end
  end
end
