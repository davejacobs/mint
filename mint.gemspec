require File.expand_path('../lib/mint/version', __FILE__)

Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version
  s.required_rubygems_version = '>= 1.3.6'
  
  s.name      = 'mint'
  s.version   = Mint::VERSION
  s.date      = '2011-02-01'
  
  s.platform  = Gem::Platform::RUBY
  s.homepage  = 'http://github.com/davejacobs/mint'
  s.author    = 'David Jacobs'
  s.email     = 'david@allthingsprogress.com'
  s.summary   = 'Clean, simple library for maintaining and styling documents without a word processor'

  # Manifest
  s.files = %w[
    README.md
    bin/mint
    lib/mint.rb
    lib/mint/mint.rb
    lib/mint/helpers.rb
  ]

  s.require_path = 'lib'
  s.executables = ['mint']

  s.add_dependency 'tilt'
end
