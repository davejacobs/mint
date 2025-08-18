require "mint/resource"

module Mint
  class Style < Resource
    # Creates a new Layout object using a mandatory source file
    # and optional configuration options.
    #
    # @param [String] source the absolute or relative file path
    # @param [Hash, #[]] opts style options
    def initialize(source, opts=Mint.default_options)
      super(source, opts)
      self.type = :style

      # We want to render final stylesheet to the /css subdirectory if
      # an output directory is not specified and we are dealing with
      # a named template (not a local file). If we don't do this, the rendered
      # CSS file might be picked up next time we look for a named template
      # in this directory, and the (correct) SASS file won't be picked up.
      # However, if a destination directory is already specified, we
      # leave it alone.
      if Mint.template?(self.source_directory) and rendered?
        tmp_dir = Mint.path_for_scope(:user, true) + "tmp"
        self.destination ||= tmp_dir.to_s
        self.root = "/"
      end
    end

    # Determines whether a Style object is supposed to be rendered.
    #
    # @return [Boolean] whether or not style should be rendered
    def rendered?
      source_file_path.extname !~ /\.css$/
    end

    # Renders a Style object if necessary. Otherwise, returns the contents
    # of its source file.
    #
    # @return [String] a rendered stylesheet
    def render
      if rendered?
        super
      else
        File.read source
      end
    end
  end
end
