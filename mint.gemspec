require File.expand_path('../lib/mint/version', __FILE__)

Gem::Specification.new do |s|
  s.specification_version = 3 if s.respond_to? :specification_version
  s.required_rubygems_version = '>= 1.3.6'
  
  s.name      = 'mint'
  s.version   = Mint::VERSION
  
  s.platform  = Gem::Platform::RUBY
  s.homepage  = 'http://github.com/davejacobs/mint'
  s.author    = 'David Jacobs'
  s.email     = 'david@wit.io'
  s.summary   = 'Clean, simple library for maintaining and styling documents without a word processor'

  # Manifest
  s.files = [
    'README.md',
    'bin/mint',
    'lib/mint.rb',
    'lib/mint/helpers.rb',
    'lib/mint/exceptions.rb',
    'lib/mint/mint.rb',
    'lib/mint/resource.rb',
    'lib/mint/layout.rb',
    'lib/mint/style.rb',
    'lib/mint/document.rb',
    'lib/mint/version.rb',
    'lib/mint/css.rb',
    'lib/mint/commandline.rb',
    'config/syntax.yaml',
    'templates/base/style.sass',
    'templates/default/layout.haml',
    'templates/default/style.sass',
    'templates/pro/layout.haml',
    'templates/pro/style.sass',
    'features/mint_document.feature',
    'features/step_definitions/mint_steps.rb',
    'features/support/env.rb',
    'spec/document_spec.rb',
    'spec/spec_helper.rb'
  ]

  s.test_files = [
    'features/mint_document.feature',
    'features/step_definitions/mint_steps.rb',
    'features/support/env.rb',
    'spec/document_spec.rb',
    'spec/spec_helper.rb'
  ]

  s.require_path = 'lib'
  s.executables  = ['mint']

  s.add_dependency 'tilt'
  s.add_dependency 'rdiscount'
  s.add_dependency 'erubis'
  s.add_dependency 'haml'
  s.add_dependency 'sass'
  s.add_dependency 'rdiscount'
  s.add_dependency 'liquid'
  s.add_dependency 'less'
  s.add_dependency 'radius'
  s.add_dependency 'markaby'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
end
