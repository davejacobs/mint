require "mint/resource"

module Mint
  class Style < Resource
    # Creates a new Style object using a mandatory source file
    # and optional configuration options.
    #
    # @param [String] source the absolute or relative file path
    def initialize(source, root: nil, destination: nil, context: nil, name: nil, &block)
      super(source, root: root, destination: destination, context: context, name: name, &block)
      self.type = :style

      # We want to render final stylesheet to the /css subdirectory if
      # an output directory is not specified and we are dealing with
      # a named template (not a local file). If we don't do this, the rendered
      # CSS file might be picked up next time we look for a named template
      # in this directory, and the (correct) SASS file won't be picked up.
      # However, if a destination directory is already specified, we
      # leave it alone.
      if Mint.template?(self.source_directory) and rendered?
        tmp_dir = Mint.path_for_scope(:user) + "tmp"
        self.destination ||= tmp_dir.to_s
        self.root = "/"
      end
    end

    # Determines whether a Style object is supposed to be rendered.
    #
    # @return [Boolean] whether or not style should be rendered
    def rendered?
      true  # All styles need rendering now (CSS for imports, Sass for compilation)
    end

    # Renders a Style object through Tilt template system
    #
    # @return [String] a rendered stylesheet  
    def render
      super
    end
  end
end
