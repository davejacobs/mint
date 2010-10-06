lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version
  s.required_rubygems_version = '>= 1.3.6'
  
  s.name = 'mint'
  s.version = '0.1.1'
  s.date = '2010-06-28'
  
  s.platform  = Gem::Platform::RUBY
  s.homepage  = 'http://github.com/davejacobs/mint/'
  s.author    = 'David Jacobs'
  s.email     = 'david@allthingsprogress.com'
  s.summary   = 'Clean, simple library for maintaining and styling documents without a word processor'

  # Manifest
  s.files = %w[
    README.md
    bin/mint
    lib/mint.rb
    templates/default/layout.haml
    templates/default/style.sass
  ]
  
  s.executables = ['mint']
  s.require_path = 'lib'
end