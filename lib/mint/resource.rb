require 'mint/mint'

module Mint
  class Resource
    attr_accessor :type

    attr_reader :source
    def source=(source)
      @source = Pathname.new(source) if source
    end
    
    # I haven't tested this - moved empty string from
    # default options into this method, so that default options
    # can be uniform - i.e., style_destination and destination
    # can each be nil to indicate that any rendering will be
    # done in the same folder the file is already in. I need
    # to make sure that adding the empty string here actually
    # keeps us in the current working directory
    attr_reader :destination
    def destination=(destination)
      @destination = Pathname.new(destination) if destination 
    end
    
    attr_reader :name
    def name=(name)
      @name = name
    end

    def renderer=(renderer)
      @renderer = renderer
    end

    def initialize(source, type=:resource, options={})
      return nil unless source

      self.source = source
      self.type = type
      self.destination = options[:destination]
      self.name = Mint.guess_name_from source
      self.renderer = Mint.renderer source
    end

    def equal?(other)
      self.destination + self.name == other.destination + other.name
    end
    alias_method :==, :equal?

    def render(context=Object.new, args={})
      # see Tilt TEMPLATES.md for more info
      @renderer.render context, args 
    end
  end
end
