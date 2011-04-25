require 'pathname'
require 'mint'

RSpec::Matchers.define :be_in_directory do |name|
  match {|resource| resource.source_directory =~ /#{name}/ }
end

RSpec.configure do |config|
  config.before(:suite) do
    @old_dir = Dir.getwd
    @tmp_dir = '/tmp/mint-test'
    @alternative_root = "#{@tmp_dir}/alternative-root"

    FileUtils.mkdir_p @tmp_dir
    Dir.chdir @tmp_dir

    # Set up alternative Mint scope?
  end

  config.after(:suite) do
    Dir.chdir @old_dir
    FileUtils.rm_r @tmp_dir
  end

  config.before(:each) do
    @content_file = 'content.md'
    @layout_file = 'layout.haml'
    @style_file = 'style.css'

    @content = <<-HERE
Header
------

This is just a test.
    HERE

    @layout = <<-HERE
!!!
%html
  %head
  %body= content
    HERE

    @style = 'body { font-size: 16px }'

    File.open @content_file, 'w' do |f|
      f << @content
    end

    File.open @layout_file, 'w' do |f|
      f << @layout
    end

    File.open @style_file, 'w' do |f|
      f << @style
    end
  end

  config.after(:each) do
    File.delete @content_file
    File.delete @layout_file
    File.delete @style_file
  end
end
