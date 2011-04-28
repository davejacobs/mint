require 'mint/resource'

module Mint
  # Style describes a resource whose type is `:style`. Beyond its type,
  # it is a simple resource. However, its type helps decide which template
  # file to use when a template name is specified.
  class Style < Resource
    def initialize(source, opts=Mint.default_options)
      super(source, opts)
      self.type = :style

      # We want to render final stylesheet to the /css subdirectory if
      # an output directory is not specified and we are dealing with
      # a named template (not a local file). If we don't do this, the rendered
      # Css file might be picked up next time we look for a named template
      # in this directory, and the (correct) Sass file won't be picked up.
      # However, if a destination directory is already specified, we
      # leave it alone.
      if Mint.template?(self.source_directory) and rendered?
        self.destination ||= 'css' 
      end
    end

    def render
      if rendered?
        super
      else
        File.read source
      end
    end

    def rendered?
      source_file_path.extname !~ /\.css$/
    end
  end
end
