require 'pathname'
require 'mint'

RSpec::Matchers.define :be_in_directory do |name|
  match {|resource| resource.source_directory =~ /#{name}/ }
end

RSpec::Matchers.define :be_path do |name|
  match {|resource| resource == Pathname.new(name) }
end

RSpec::Matchers.define :be_in_template do |name|
  match {|file| file =~ /#{Mint.root}.*#{name}/ }
end

RSpec::Matchers.define :be_a_template do |name|
  match {|file| Mint.template? file }
end

RSpec.configure do |config|
  config.before(:suite) do
    @old_dir = Dir.getwd
    @tmp_dir = '/tmp/mint-test'

    FileUtils.mkdir_p @tmp_dir
    Dir.chdir @tmp_dir
  end

  config.after(:suite) do
    Dir.chdir @old_dir
    FileUtils.rm_r @tmp_dir
  end

  config.before(:each) do
    @content_file = 'content.md'
    @destination_file = 'content.html'
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
    erase = lambda do |file|
      filename = instance_variable_get(:"@#{file}_file")
      File.delete(filename) if File.file?(filename)
    end

    [:content, :destination, :layout, 
     :style, :static_style, :dynamic_style].each &erase
  end
end
