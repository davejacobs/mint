require 'spec_helper'

describe Mint do
  # Remove unintended side effects of creating
  # new plugins in other files.
  before { Mint.clear_plugins! }
  after { Mint.clear_plugins! }

  describe ".plugins" do
    it "returns all registered plugins" do
      plugin = Class.new(Mint::Plugin)
      Mint.plugins.should == [plugin]
    end

    it "returns an empty array if there are no registered plugins" do
      Mint.plugins.should == []
    end
  end

  describe ".register_plugin!" do
    let(:plugin) { Class.new }

    it "registers a plugin once" do
      Mint.register_plugin! plugin
      Mint.plugins.should == [plugin]
    end

    it "does not register a plugin more than once" do
      Mint.register_plugin! plugin
      lambda { Mint.register_plugin! plugin }.should_not change { Mint.plugins }
      Mint.plugins.should == [plugin]
    end
  end

  describe ".activate_plugin!" do
    let(:plugin) { Class.new }

    it "activates a plugin once" do
      Mint.activate_plugin! plugin
      Mint.activated_plugins.should == [plugin]
    end

    it "does not register a plugin more than once" do
      Mint.activate_plugin! plugin
      lambda { Mint.activate_plugin! plugin }.should_not change { Mint.activated_plugins }
      Mint.activated_plugins.should == [plugin]
    end
  end

  describe ".clear_plugins!" do
    let(:plugin) { Class.new }

    it "does nothing if no plugins are registered" do
      lambda { Mint.clear_plugins! }.should_not raise_error
    end

    it "removes all registered plugins" do
      Mint.register_plugin! plugin
      lambda { Mint.clear_plugins! }.should change { Mint.plugins.length }.by(-1)
    end

    it "removes all activated plugins" do
      Mint.activate_plugin! plugin
      lambda { Mint.clear_plugins! }.should change { Mint.activated_plugins.length }.by(-1)
    end
  end

  describe ".template_directory" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      plugin.should_receive(:name).and_return('DocBook')
      Mint.template_directory(plugin).should == 
        Mint.root + '/plugins/templates/doc_book'
    end
  end

  describe ".config_directory" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      plugin.should_receive(:name).and_return('DocBook')
      Mint.config_directory(plugin).should == 
        Mint.root + '/plugins/config/doc_book'
    end
  end

  describe ".commandline_options_file" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      plugin.should_receive(:name).and_return('DocBook')
      Mint.commandline_options_file(plugin).should == 
        Mint.root + '/plugins/config/doc_book/syntax.yml'
    end
  end

  [:before_render, :after_render].each do |callback|
    describe ".#{callback}" do
      let(:first_plugin) { Class.new(Mint::Plugin) }
      let(:second_plugin) { Class.new(Mint::Plugin) }
      let(:third_plugin) { Class.new(Mint::Plugin) }

      context "when plugins are specified" do
        before do
          first_plugin.should_receive(callback).ordered.and_return('first')
          second_plugin.should_receive(callback).ordered.and_return('second')
          third_plugin.should_receive(callback).never
        end

        it "reduces .#{callback} across all specified plugins in order" do
          plugins = [first_plugin, second_plugin]
          Mint.send(callback, 'text', :plugins => plugins).should == 'second'
        end
      end

      context "when plugins are activated, but no plugins are specified" do
        before do
          first_plugin.should_receive(callback).ordered.and_return('first')
          second_plugin.should_receive(callback).ordered.and_return('second')
          third_plugin.should_receive(callback).never
        end
        
        it "reduces .#{callback} across all activated plugins in order" do
          Mint.activate_plugin! first_plugin
          Mint.activate_plugin! second_plugin
          Mint.send(callback, 'text').should == 'second'
        end
      end

      context "when plugins are not specified" do
        before do
          first_plugin.should_receive(callback).never
          second_plugin.should_receive(callback).never
          third_plugin.should_receive(callback).never
        end
        
        it "returns the parameter text" do
          Mint.send(callback, 'text').should == 'text'
        end
      end
    end
  end

  describe ".after_publish" do
    let(:first_plugin) { Class.new(Mint::Plugin) }
    let(:second_plugin) { Class.new(Mint::Plugin) }
    let(:third_plugin) { Class.new(Mint::Plugin) }

    context "when plugins are specified" do
      before do
        first_plugin.should_receive(:after_publish).ordered
        second_plugin.should_receive(:after_publish).ordered
        third_plugin.should_receive(:after_publish).never
      end

      it "iterates across all specified plugins in order" do
        plugins = [first_plugin, second_plugin]
        Mint.after_publish('fake document', :plugins => plugins)
      end
    end

    context "when plugins are activated, but no plugins are specified" do
      before do
        first_plugin.should_receive(:after_publish).ordered
        second_plugin.should_receive(:after_publish).ordered
        third_plugin.should_receive(:after_publish).never
      end
      
      it "iterates across all activated plugins in order" do
        Mint.activate_plugin! first_plugin
        Mint.activate_plugin! second_plugin
        Mint.after_publish('fake document')
      end
    end

    context "when plugins are not specified" do
      before do
        first_plugin.should_receive(:after_publish).never
        second_plugin.should_receive(:after_publish).never
        third_plugin.should_receive(:after_publish).never
      end
      
      it "does not iterate over any plugins" do
        Mint.after_publish('fake document')
      end
    end
  end

  # TODO: Document expected document functionality changes related to plugins
  describe Mint::Document do
    context "when plugins are registered with Mint" do
      describe "#content=" do
        it "applies each registered plugin's before_render filter"
      end

      describe "#render" do
        it "applies each registered plugin's after_render filter"
      end

      describe "#publish!" do
        it "applies each registered plugin's after_publish filter"
      end
    end
  end

  describe Mint::Plugin do
    # We have to instantiate these plugins in a before block,
    # and not in a let block. Because lets are lazily evaluated,
    # the first two tests in the '#inherited' suite will not
    # pass.
    before do
      @first_plugin = Class.new(Mint::Plugin)
      @second_plugin = Class.new(Mint::Plugin)
    end

    describe ".underscore" do
      let(:plugin) { Class.new(Mint::Plugin) }

      it "when anonymous, returns a random identifier"

      it "when named, returns its name, underscored" do
        plugin.should_receive(:name).and_return('EPub')
        plugin.underscore.should == 'epub'
      end
    end

    describe ".inherited" do
      it "registers the subclass with Mint as a plugin" do
        lambda do
          Class.new(Mint::Plugin)
        end.should change { Mint.plugins.length }.by(1)
      end

      it "preserves the order of subclassing" do
        Mint.plugins.should == [@first_plugin, @second_plugin]
      end

      it "does not change the order of a plugin when it is monkey-patched" do
        lambda do
          @first_plugin.instance_eval do 
            def monkey_patch
            end
          end
        end.should_not change { Mint.plugins }
      end
    end

    describe ".commandline_options" do
      let(:plugin) { Class.new(Mint::Plugin) }
      before do
        plugin.instance_eval do
          def commandline_options
          end
        end
      end

      it "returns a hash of options the plugin can take, including constraints"
    end

    context "plugin callbacks" do
      let(:plugin) { Class.new(Mint::Plugin) }

      describe ".before_render" do
        it "allows changes to the un-rendered content" do
          plugin.instance_eval do
            def before_render(text_document)
              'base'
            end
          end

          plugin.before_render('text').should == 'base'
        end
      end

      describe ".after_render" do
        it "allows changes to the rendered HTML" do
          plugin.instance_eval do
            def after_render(html_document)
              '<!doctype html>'
            end
          end

          plugin.after_render('<html></html>').should == '<!doctype html>'
        end
      end

      describe ".after_mint" do
        let(:document) { Mint::Document.new 'content.md' } 

        it "allows changes to the document extension" do
          plugin.instance_eval do
            def after_publish(document)
              document.name.gsub! /html$/, 'htm'
            end
          end

          lambda do
            plugin.after_publish(document)
          end.should change { document.name.length }.by(-1)
        end

        it "allows splitting up the document into two, without garbage" do
          plugin.instance_eval do
            def after_publish(document)
              content = document.content
              fake_splitting_point = content.length / 2

              first  = content[0..fake_splitting_point]
              second = content[fake_splitting_point..-1]

              File.open 'first-half.html', 'w+' do |file|
                file << first
              end

              File.open 'second-half.html', 'w+' do |file|
                file << second
              end

              File.delete document.destination_file
            end
          end

          document.publish! :plugins => [plugin]

          File.exist?(document.destination_file).should be_false
          File.exist?('first-half.html').should be_true
          File.exist?('second-half.html').should be_true
        end

        it "allows changes to the style file" do
          pending "figure out a better strategy for style manipulation"
          document = Mint::Document.new 'content.md', :style => 'style.css' 

          plugin.instance_eval do
            def after_publish(document)
              # I'd like to take document.style_destination_file,
              # but the current Mint API doesn't allow for this
              # if we're setting the style via a concrete
              # stylesheet in our current directory
              style_source = document.style.source_file
              style = File.read style_source
              File.open style_source, 'w' do |file|
                file << style.gsub(/#/, '.')
              end
            end
          end

          document.publish! :plugins => [plugin]

          File.read(document.style.source_file).should =~ /\#container/
        end

        context "when the output is in the default directory" do
          it "doesn't allow changes to the document directory" do
            pending "figuring out the best way to prevent directory manipulation"
            document = Mint::Document.new 'content.md'
            plugin.instance_eval do
              def after_publish
                original = document.destination_directory
                new = File.expand_path 'invalid'
                FileUtils.mv original, new
                document.destination = 'invalid'
              end

              lambda do
                document.publish! :plugins => [plugin]
              end.should raise_error(InvalidPluginAction)
            end
          end
        end

        context "when the output is a new directory" do
          it "allows changes to the document directory" do
            document = Mint::Document.new 'content.md', :destination => 'destination'
            plugin.instance_eval do
              def after_publish(document)
                original = document.destination_directory
                new = File.expand_path 'book'
                FileUtils.mv original, new
                document.destination = 'book'
              end
            end

            document.publish! :plugins => [plugin]
            File.exist?('destination').should be_false
            File.exist?('book').should be_true
            document.destination_directory.should == File.expand_path('book')
          end

          it "allows compression of the final output" do
            require 'zip/zip'
            require 'zip/zipfilesystem'

            document = Mint::Document.new 'content.md', :destination => 'destination'
            plugin.instance_eval do
              def after_publish(document)
                Zip::ZipOutputStream.open 'book.zip' do |zos|
                  # zos.put_next_entry('mimetype', nil, nil, Zip::ZipEntry::STORED)
                  # zos.puts 'text/epub'
                  zos.put_next_entry('chapter-1', nil, nil, Zip::ZipEntry::DEFLATED)
                  zos.puts File.read(document.destination_file)
                end

                FileUtils.mv 'book.zip', 'book.epub'
              end
            end

            document.publish! :plugins => [plugin]

            File.exist?('destination').should be_true
            File.exist?('book.zip').should be_false
            File.exist?('book.epub').should be_true

            directory_size = 
              Dir["#{document.destination_directory}/**/*"].
              flatten.
              map {|file| File.stat(file).size }.
              reduce(&:+)
            compressed_size = File.stat('book.epub').size
            directory_size.should > compressed_size
          end
        end

        context "when the style output is a new directory" do
          it "allows changes to the style directory" do
            document = Mint::Document.new 'content.md', :style_destination => 'styles'
            plugin.instance_eval do
              def after_publish(document)
                original = document.style_destination_directory
                new = File.expand_path 'looks'
                FileUtils.mv original, new
                document.style_destination = 'looks'
              end
            end

            document.publish! :plugins => [plugin]

            File.exist?('styles').should be_false
            File.exist?('looks').should be_true
            document.style_destination_directory.should == File.expand_path('looks')
          end

          after do
            FileUtils.rm_r File.expand_path('looks')
          end
        end
      end
    end
  end
end
