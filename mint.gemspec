require File.expand_path("../lib/mint/version", __FILE__)

Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version
  s.required_rubygems_version = ">= 1.3.6"
  s.required_ruby_version = ">= 3.0"
  
  s.name        = "mint"
  s.version     = Mint::VERSION
  
  s.platform    = Gem::Platform::RUBY
  s.homepage    = "https://github.com/davejacobs/mint"
  s.author      = "David Jacobs"
  s.email       = "david@wit.io"
  s.license     = "MIT"
  s.summary     = "Publish Markdown documents and notebooks without a word processor"
  s.description = "Clean, simple library for maintaining and styling documents without a word processor. Mint aims to bring the best of the Web to desktop publishing, to be completely flexible, and to let the user decide what his workflow is like. A powerful plugin system means almost any conceivable publishing target is an option."
  
  s.executables  = ["mint", "mint-epub"]
  s.require_path = "lib"

  s.files = Dir["{bin,config,lib,plugins,man}/**/*"] + [
    "README.md",
    "Gemfile",
    "LICENSE"
  ]

  s.test_files = Dir["{features,spec}/**/*"]
  
  s.add_dependency "tilt", "~> 2.6", ">= 2.6.1"
  s.add_dependency "redcarpet", "~> 3.6", ">= 3.6.1"
  s.add_dependency "haml", "~> 6.3"
  s.add_dependency "sass-embedded", "~> 1.89", ">= 1.89.2"
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "activesupport", "~> 8.0", ">= 8.0.2.1"
  s.add_dependency "nokogiri", "~> 1.15.0"
  s.add_dependency "hashie", "~> 5.0"
  s.add_dependency "rubyzip", "~> 3.0", ">= 3.0.1"
end
