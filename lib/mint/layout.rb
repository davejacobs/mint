require "pathname"

module Mint
  module Layout
    HTML_EXTENSIONS = ["html", "erb"]
    
    # Indicates whether the file is a valid layout file
    #
    # @param [Pathname] pathname the pathname to check
    # @return [Boolean] true if the file is a valid layout file
    def self.valid?(pathname)
      HTML_EXTENSIONS.map {|ext| "layout.#{ext}" }.include? pathname.basename.to_s
    end
    
    # Returns the layout file for the given template name
    #
    # @param [String] name the template name or directory path to look up
    # @return [Pathname] path to the layout file
    def self.find_by_name(name)
      find_in_directory Template.find_directory_by_name(name)
    end
    
    # Finds the layout file in a specific directory
    #
    # @param [Pathname] directory the directory to look in
    # @return [Pathname] path to the layout file
    def self.find_in_directory(directory)
      directory&.children&.select(&:file?)&.select(&method(:valid?))&.first
    end
  end
end