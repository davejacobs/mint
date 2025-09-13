require "pathname"

module Mint
  module Template
    # Indicates whether the directory is a valid template directory.
    #
    # @param [Pathname] directory the directory to check
    # @return [Boolean] true if the directory is a valid template directory
    def self.valid?(directory)
      # Note that typically templates have only a stylesheet, although they can
      # optionally include a layout file. Most templates can get by with the layout
      # provided by the default template, which is automatically used if no layout
      # file is provided in the template directory.
      directory.children.
        select(&:file?).
        select(&Style.method(:valid?))
    end
    
    # Finds a template directory by name
    #
    # @param [String] name the template name to find
    # @return [Pathname] path to the template directory
    def self.find_directory_by_name(name)
      Mint::PATH.
        map {|p| p + Mint::TEMPLATES_DIRECTORY + name }.
        select(&:exist?).
        first
    end
  end
end