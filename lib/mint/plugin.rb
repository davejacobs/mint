require 'mint/document'

module Mint
  def self.register_plugin(plugin)
    @plugins << plugin
  end

  def self.process
    
  end
  
  def self.process_with(plugin)
  end

  class Plugin
    def self.inherited(subclass)
      Mint.register_plugin(subclass)
    end

    def commandline_options
    end

    def before_render; end
    def after_render; end
    def after_mint; end
  end
end
