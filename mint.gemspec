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
    'bin/mint-epub',
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
    'lib/mint/plugin.rb',
    'lib/mint/plugins/epub.rb',
    'config/syntax.yaml',
    'templates/base/style.sass',
    'templates/default/layout.haml',
    'templates/default/style.sass',
    'templates/pro/layout.haml',
    'templates/pro/style.sass',
    'plugins/templates/epub/layouts/container.haml',
    'plugins/templates/epub/layouts/layout.haml',
    'plugins/templates/epub/layouts/title.haml',
    'plugins/templates/epub/layouts/toc.haml',
    'plugins/templates/epub/layouts/content.haml',
    'features/support/env.rb',
    'features/publish.feature',
    'features/plugins/epub.feature',
    'spec/spec_helper.rb',
    'spec/helpers_spec.rb',
    'spec/mint_spec.rb',
    'spec/resource_spec.rb',
    'spec/layout_spec.rb',
    'spec/style_spec.rb',
    'spec/document_spec.rb',
    'spec/commandline_spec.rb',
    'spec/plugin_spec.rb',
    'spec/plugins/epub_spec.rb'
  ]

  s.test_files = [
    'features/support/env.rb',
    'features/publish.feature',
    'features/plugins/epub.feature',
    'spec/spec_helper.rb',
    'spec/helpers_spec.rb',
    'spec/mint_spec.rb',
    'spec/resource_spec.rb',
    'spec/layout_spec.rb',
    'spec/style_spec.rb',
    'spec/document_spec.rb',
    'spec/commandline_spec.rb',
    'spec/plugin_spec.rb',
    'spec/plugins/epub_spec.rb'
  ]

  s.require_path = 'lib'
  s.executables  = ['mint', 'mint-epub']

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
  s.add_dependency 'active_support'
  s.add_dependency 'nokogiri'
  s.add_dependency 'hashie'
  s.add_dependency 'rubyzip'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'cucumber'
  s.add_development_dependency 'aruba'
end
