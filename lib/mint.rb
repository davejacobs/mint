require "pathname"
require "fileutils"
require "yaml"
require "active_support/core_ext/string/output_safety"

require_relative "mint/version"
require_relative "mint/commandline/run"
require_relative "mint/commandline/parse"
require_relative "mint/css_dsl"
require_relative "mint/css_parser"
require_relative "mint/config"
require_relative "mint/exceptions"
require_relative "mint/renderers/css_renderer"
require_relative "mint/renderers/markdown_renderer"
require_relative "mint/renderers/erb_renderer"
require_relative "mint/document"
require_relative "mint/workspace"
require_relative "mint/layout"
require_relative "mint/style"
require_relative "mint/template"

module Mint
  PROJECT_ROOT        = (Pathname.new(__FILE__).realpath.dirname + "..").to_s
  LOCAL_SCOPE         = Pathname.new(".mint")
  USER_SCOPE          = Pathname.new("~/.config/mint").expand_path
  GLOBAL_SCOPE        = Pathname.new("#{PROJECT_ROOT}/config").expand_path
  PATH                = [LOCAL_SCOPE, USER_SCOPE, GLOBAL_SCOPE]
  CONFIG_FILE         = "config.toml"
  TEMPLATES_DIRECTORY = "templates"
  
  # Returns a hash of all active config, merging global, user, and local
  # scoped config. Local overrides user, which overrides global config.
  #
  # @return [Config] a structured set of configuration options
  def self.configuration
    Mint::PATH.
      reverse.
      map {|p| p + Mint::CONFIG_FILE }.
      select(&:exist?).
      map {|p| Config.load_file p }.
      reduce(Config.defaults) {|agg, cfg| agg.merge cfg }
  end
end
