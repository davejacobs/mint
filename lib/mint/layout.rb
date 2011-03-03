require 'mint/resource'

module Mint
  # Layout describes a resource whose type is `:layout`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Layout < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, :layout, opts)
    end
  end
end
