require 'mint/resource'

module Mint
  class Layout < Resource
    # Creates a new Layout object using a mandatory source file
    # and optional configuration options.
    def initialize(source, opts=Mint.default_options)
      super(source, opts)
      self.type = :layout
    end
  end
end
