require 'mint/resource'

module Mint
  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, opts)
      self.type = :style

      # We want to render final stylesheet to css subdirectory if
      # an output directory is not specified. If we don't, the rendered
      # Css file might be picked up next time we look for a named template
      # in this directory, and any changes to the master Sass file
      # won't be picked up.
      self.destination ||= self.source_directory_path + 'css'
    end

    def render
      if need_rendering?
        super
      else
        File.read source
      end
    end

    def need_rendering?
      source_file_path.extname !~ /\.css$/
    end
  end
end
