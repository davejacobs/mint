require 'mint/document'
require 'set'

module Mint
  def self.plugins
    @@plugins ||= Set.new
    @@plugins.to_a
  end

  def self.register_plugin!(plugin)
    @@plugins ||= Set.new
    @@plugins << plugin
  end

  def self.clear_plugins!
    @@plugins.clear
  end

  def self.before_render(plain_text)
    plugins.reduce(plain_text) do |intermediate, plugin|
      plugin.before_render(intermediate)
    end
  end

  def self.after_render(html_text)
    plugins.reduce(html_text) do |intermediate, plugin|
      plugin.after_render(intermediate)
    end
  end

  def self.after_publish(document)
    plugins.each do |plugin|
      plugin.after_publish(document)
    end
  end

  class Plugin
    def self.inherited(plugin)
      Mint.register_plugin! plugin
    end

    def commandline_options
    end

    # Supports:
    # - Change raw text
    #
    # Use cases:
    # - Add footnote syntax on top of Markdown
    # - Perform text analysis for use in later callbacks (?)
    def self.before_render(text_document)
      text_document
    end

    # Supports:
    # - Change preview HTML
    #
    # Use cases:
    # - Transform elements based on position or other HTML attributes
    #   For example: Add a class to the first paragraph of a document if it is
    #   italicized
    #
    # Questions:
    # - Could I allow jQuery use here?
    def self.after_render(html_document)
      html_document
    end

    # Supports:
    # - Change file, filesystem once written
    # - Automatic cleanup of intermediate files, including all edge cases
    #   currently covered by transformation library. (For example, if I generated
    #   a CSS file but am ultimately generating a PDF, I would want to have 
    #   an automatic way to delete that CSS file.)
    #
    # Use cases:
    # - Zip set of documents into ePub and create manifest 
    # - Change file extension
    # - Generate PDF from emitted HTML and get rid of intermediate files
    # - Generate .doc (or any other OO UNO format) and get rid of intermediate files
    #
    # NOTE: Unlike the other two callbacks, this doesn't use the result of 
    #   the callback expression for anything. This callback is purely for 
    #   side effects like rearranging the file system.
    def self.after_publish(document)
    end
  end
end
