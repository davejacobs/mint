require 'pathname'
require 'mint'
require_relative 'support/matchers'

RSpec.configure do |config|
  config.before(:all) do
    @old_dir = Dir.getwd
    FileUtils.mkdir_p '/tmp/mint-test'
    @tmp_dir = File.realpath '/tmp/mint-test'

    @content_file = 'content.md'
    @layout_file = 'layout.haml'
    @static_style_file = 'static.css'
    @dynamic_style_file = 'dynamic.sass'

    ['content.md', 'layout.haml', 'static.css', 'dynamic.sass'].each do |file|
      FileUtils.cp "spec/support/fixtures/#{file}", @tmp_dir
    end

    Dir.chdir @tmp_dir
  end

  config.after(:all) do
    Dir.chdir @old_dir
    FileUtils.rm_r @tmp_dir
  end

  config.after(:each) do
    ['content.html', '.mint/defaults.yaml'].map {|file| Pathname.new file }.
      select(&:exist?).
      each {|file| FileUtils.rm_rf file }

    Mint.templates.
      map {|template| Pathname.new(template) + 'css' }.
      select(&:exist?).
      map(&:children).
      flatten.
      each {|cache| File.delete(cache) }
  end
end
