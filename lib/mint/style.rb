require 'mint/resource'

module Mint
  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, :style, opts)
      self.destination ||= source.dirname.expand_path
    end

    def needs_rendering?
      source.extname !~ /\.css$/
    end
  end
end
