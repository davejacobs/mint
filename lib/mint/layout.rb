require "mint/resource"

module Mint
  class Layout < Resource
    # Creates a new Layout object using a mandatory source file
    # and optional configuration options.
    #
    # @param [String] source the absolute or relative file path
    def initialize(source, root: nil, destination: nil, context: nil, name: nil, &block)
      super(source, root: root, destination: destination, context: context, name: name, &block)
      self.type = :layout
    end
  end
end
