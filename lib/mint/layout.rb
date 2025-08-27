require "mint/resource"

module Mint
  class Layout < Resource
    # Creates a new Layout object using a mandatory source file
    # and optional configuration options.
    #
    # @param [String] source the absolute or relative file path
    # @param [Hash, #[]] opts layout options
    def initialize(source, opts = {})
      options = Mint.default_options.merge opts
      super(source, options)
      self.type = :layout
    end
  end
end
