require File.expand_path('../lib/mint/version', __FILE__)

Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version
  s.required_rubygems_version = '>= 1.3.6'
  
  s.name      = 'mint'
  s.version   = Mint::VERSION
  
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
    lib/mint/helpers.rb
    lib/mint/mint.rb
    lib/mint/version.rb
    lib/mint/css.rb
    lib/mint/commandline.rb
    config/options.yaml
    templates/default/layout.haml
    templates/default/style.css
    templates/pro/layout.haml
    templates/pro/style.sass
    features/mint_document.feature
    features/step_definitions/mint_steps.rb
    features/support/env.rb
    spec/document_spec.rb
    spec/spec_helper.rb
  ]

  s.test_files = %w[
    features/mint_document.feature
    features/step_definitions/mint_steps.rb
    features/support/env.rb
    spec/document_spec.rb
    spec/spec_helper.rb
  ]

  s.require_path = 'lib'
  s.executables  = ['mint']

  s.add_dependency 'tilt'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
end
