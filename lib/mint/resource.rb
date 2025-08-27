require "mint/mint"

module Mint
  class Resource
    attr_accessor :type

    attr_accessor :context

    attr_reader :name
    def name=(name)
      @name = name
    end

    attr_reader :root
    def root=(root)
      @root = root
    end

    def root_directory_path
      Pathname.new(root || Dir.getwd).expand_path
    end

    def root_directory
      root_directory_path.to_s
    end

    attr_accessor :source

    def source_file_path
      path = Pathname.new(source)
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
      root_directory_path + (destination || "") + name
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

    def initialize(source, root: nil, destination: nil, context: nil, name: nil, &block)
      return nil unless source

      self.type = :resource
      self.source = source
      self.root = root || source_directory
      self.destination = destination
      self.context = context

      yield self if block

      self.name = name || Mint.guess_name_from(source)
      self.renderer = Mint.renderer source
    end

    def equal?(other)
      self.destination_file_path == other.destination_file_path
    end
    alias_method :==, :equal?

    def render(context=self, args={})
      # see Tilt TEMPLATES.md for more info
      @renderer.render context, args
    end

    def publish!(opts={})
      FileUtils.mkdir_p self.destination_directory
      File.open(self.destination_file, "w+") do |f|
        f << self.render
      end
    end
  end
end
