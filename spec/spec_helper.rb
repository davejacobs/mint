require 'pathname'
require 'mint'

RSpec::Matchers.define :be_in_directory do |name|
  match {|resource| resource.source_directory =~ /#{name}/ }
end

RSpec::Matchers.define :be_in_template do |name|
  match {|file| file =~ /#{Mint.root}.*#{name}/ }
end

RSpec.configure do |config|
  config.before(:suite) do
    @old_dir = Dir.getwd
    @tmp_dir = '/tmp/mint-test'
    @alternative_root = "#{@tmp_dir}/alternative-root"

    FileUtils.mkdir_p @tmp_dir
    Dir.chdir @tmp_dir
  end

  config.after(:suite) do
    Dir.chdir @old_dir
    FileUtils.rm_r @tmp_dir
  end

  config.before(:each) do
    @content_file = 'content.md'
    @layout_file = 'layout.haml'
    @style_file = 'style.css'

    @static_style_file = 'static.css'
    @dynamic_style_file = 'dynamic.sass'

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

    @static_style = <<-HERE
body #container {
  padding: 1em;
}
    HERE

    @dynamic_style = <<HERE
body
  #container
    padding: 1em
HERE

    [:content, :layout, :style, :static_style, :dynamic_style ].each do |v|
      File.open(instance_variable_get(:"@#{v}_file"), 'w') do |f|
        f << instance_variable_get(:"@#{v}")
      end
    end
  end

  config.after(:each) do
    [:content, :layout, :style, :static_style, :dynamic_style ].each do |v|
      File.delete instance_variable_get(:"@#{v}_file")
    end
  end
end
