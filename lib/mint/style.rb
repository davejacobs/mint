require "pathname"

module Mint
  module Style
    CSS_EXTENSIONS = ["css"]
    
    # Indicates whether the file is a valid stylesheet
    #
    # @param [Pathname] pathname the pathname to check
    # @return [Boolean] true if the file is a valid stylesheet
    def self.valid?(pathname)
      CSS_EXTENSIONS.map {|ext| "style.#{ext}" }.include? pathname.basename.to_s
    end
    
    # Returns the style file for the given template name
    #
    # @param [String] name the template name to look up
    # @return [Pathname] path to the style file
    def self.find_by_name(name)
      find_in_directory Template.find_directory_by_name(name)
    end

    # Finds the style file in a specific directory
    #
    # @param [Pathname] directory the directory to look in
    # @return [Pathname] path to the style file
    def self.find_in_directory(directory)
      directory&.children&.select(&:file?)&.select(&method(:valid?))&.first
    end
  end
end