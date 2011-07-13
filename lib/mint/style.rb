require 'mint/resource'

module Mint
  class Style < Resource
    # Creates a new Layout object using a mandatory source file
    # and optional configuration options.
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

    # Determines whether a Style object is supposed to be rendered.
    def rendered?
      source_file_path.extname !~ /\.css$/
    end

    # Renders a Style object if necessary. Otherwise, returns the contents
    # of its source file.
    def render
      if rendered?
        super
      else
        File.read source
      end
    end
  end
end
