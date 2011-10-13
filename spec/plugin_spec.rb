require 'spec_helper'

describe Mint do
  describe "#plugins" do
    after { Mint.clear_plugins! }

    it "returns all registered plugins" do
      plugin = Class.new(Mint::Plugin)
      Mint.plugins.should == [plugin]
    end

    it "returns an empty array if there are no registered plugins" do
      Mint.plugins.should == []
    end
  end

  describe "#register_plugin!" do
    before { @plugin = Class.new }
    after { Mint.clear_plugins! }

    it "registers a plugin once" do
      Mint.register_plugin! @plugin
      Mint.plugins.should == [@plugin]
    end

    it "does not register a plugin more than once" do
      Mint.register_plugin! @plugin
      lambda { Mint.register_plugin! @plugin }.should_not change { Mint.plugins }
      Mint.plugins.should == [@plugin]
    end
  end

  describe "#clear_plugins!" do
    before { @plugin = Class.new }
    after { Mint.clear_plugins! }

    it "does nothing if no plugins are registered" do
      lambda { Mint.clear_plugins! }.should_not raise_error
    end

    it "removes all registered plugins" do
      Mint.register_plugin! @plugin
      lambda { Mint.clear_plugins! }.should change { Mint.plugins.length }.by(-1)
    end
  end

  [:before_render, :after_render].each do |callback|
    describe "##{callback}" do
      before do
        @base_plugin   = Class.new(Mint::Plugin)
        @first_plugin  = Class.new(@base_plugin)
        @second_plugin = Class.new(@base_plugin)

        @base_plugin.should_receive(callback).
          ordered.and_return('transformed by base')
        @first_plugin.should_receive(callback).
          ordered.and_return('transformed by first')
        @second_plugin.should_receive(callback).
          ordered.and_return('transformed by second')
      end

      after { Mint.clear_plugins! }

      it "reduces ##{callback} across all registered plugins in order" do
        Mint.send(callback, 'text').should == 'transformed by second'
      end
    end
  end

  describe "#after_publish" do
    before do
      @base_plugin   = Class.new(Mint::Plugin)
      @first_plugin  = Class.new(@base_plugin)
      @second_plugin = Class.new(@base_plugin)

      @base_plugin.should_receive(:after_publish).ordered.and_return(nil)
      @first_plugin.should_receive(:after_publish).ordered.and_return(nil)
      @second_plugin.should_receive(:after_publish).ordered.and_return(nil)
    end

    after { Mint.clear_plugins! }

    it "calls each registered plugin in order, passing it a document" do
      Mint.after_publish('fake document')
    end
  end

  # TODO: Document expected document functionality changes related to plugins
  describe Mint::Document do
    context "when plugins are registered with Mint" do
      describe "#content=" do
        it "applies each registered plugin's before_render filter"
        it "applies each registered plugin's after_render filter"
        it "applies each registered plugin's after_publish filter"
      end
    end
  end

  describe Mint::Plugin do
    before do
      @base_plugin   = Class.new(Mint::Plugin)
      @first_plugin  = Class.new(@base_plugin)
      @second_plugin = Class.new(@base_plugin)
    end

    after { Mint.clear_plugins! }

    describe "#inherited" do
      it "registers the subclass with Mint as a plugin" do
        lambda do
          @plugin = Class.new(Mint::Plugin)
        end.should change { Mint.plugins.length }.by(1)
      end

      it "preserves the order of subclassing" do
        Mint.plugins.should == [@base_plugin, @first_plugin, @second_plugin]
      end

      it "does not change the order of a plugin when it is monkey-patched" do
        lambda do
          @base_plugin.instance_eval do 
            def monkey_patch
            end
          end
        end.should_not change { Mint.plugins }
      end
    end

    describe "#commandline_options" do
      before do
        @plugin = Class.new(Mint::Plugin)
        @plugin.instance_eval do
          def commandline_options
          end
        end
      end

      it "returns a hash of options the plugin can take, including constraints" do

      end
    end

    context "plugin callbacks" do
      before do
        @plugin = Class.new(Mint::Plugin)
      end

      describe "#before_render" do
        it "allows changes to the un-rendered content" do
          @plugin.instance_eval do
            def before_render(text_document)
              'transformed by base'
            end
          end

          @plugin.before_render('text').should == 'transformed by base'
        end
      end

      describe "#after_render" do
        it "allows changes to the rendered HTML" do
          @plugin.instance_eval do
            def after_render(html_document)
              '<!doctype html>'
            end
          end

          @plugin.after_render('<html></html>').should == '<!doctype html>'
        end
      end

      describe "#after_mint" do
        before do
          @document = Mint::Document.new 'content.md' 
        end

        it "allows changes to the document extension" do
          @plugin.instance_eval do
            def after_publish(document)
              document.name.gsub! /html$/, 'htm'
            end
          end

          lambda do
            @plugin.after_publish(@document)
          end.should change { @document.name.length }.by(-1)
        end

        it "allows changes to the document type" do
          pending "figuring out what I actually meant by this"
        end

        it "allows splitting up the document into two, without garbage" do
          @plugin.instance_eval do
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

          @document.publish!
          File.exist?(@document.destination_file).should be_false
          File.exist?('first-half.html').should be_true
          File.exist?('second-half.html').should be_true
        end

        it "allows changes to the style file" do
          @plugin.instance_eval do
            def after_publish(document)

              File.delete document.destination_file
            end
          end
        end

        it "allows changes to the document directory"
        it "allows changes to the style directory"
        it "allows changes to the style directory"
        it "allows packaging of the final output"
      end
    end
  end
end
