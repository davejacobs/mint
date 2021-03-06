require "mint/document"
require "set"

module Mint
  def self.plugins
    @@plugins ||= Set.new
    @@plugins.to_a
  end

  def self.activated_plugins
    @@activated_plugins ||= Set.new
    @@activated_plugins.to_a
  end

  def self.register_plugin!(plugin)
    @@plugins ||= Set.new
    @@plugins << plugin
  end

  def self.activate_plugin!(plugin)
    @@activated_plugins ||= Set.new
    @@activated_plugins << plugin
  end

  def self.clear_plugins!
    defined?(@@plugins) && @@plugins.clear
    defined?(@@activated_plugins) && @@activated_plugins.clear
  end

  def self.template_directory(plugin)
    Mint.root + "/plugins/templates/" + plugin.underscore
  end

  def self.config_directory(plugin)
    Mint.root + "/plugins/config/" + plugin.underscore
  end

  def self.commandline_options_file(plugin)
    plugin.config_directory + "/syntax.yml"
  end

  def self.commandline_name(plugin)
    plugin.underscore
  end

  def self.before_render(plain_text, opts={})
    active_plugins = opts[:plugins] || Mint.activated_plugins
    active_plugins.reduce(plain_text) do |intermediate, plugin|
      plugin.before_render(intermediate)
    end
  end

  def self.after_render(html_text, opts={})
    active_plugins = opts[:plugins] || Mint.activated_plugins
    active_plugins.reduce(html_text) do |intermediate, plugin|
      plugin.after_render(intermediate)
    end
  end

  def self.after_publish(document, opts={})
    active_plugins = opts[:plugins] || Mint.activated_plugins
    active_plugins.each do |plugin|
      plugin.after_publish(document)
    end
  end

  class Plugin
    def self.inherited(plugin)
      Mint.register_plugin! plugin
    end

    def self.underscore(opts={})
      opts[:ignore_prefix] ||= true
      Helpers.underscore self.name, :ignore_prefix => opts[:ignore_prefix]
    end

    def self.template_directory
      Mint.template_directory(self)
    end

    def self.config_directory
      Mint.config_directory(self)
    end

    def self.commandline_options_file
      Mint.commandline_options_file(self)
    end

    def self.commandline_name
      Mint.commandline_name(self)
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
