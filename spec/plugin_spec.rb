require 'spec_helper'

describe Mint do
  describe "#plugins"

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
          @base_plugin.instance_eval { def monkey_patch; end }
        end.should_not change { Mint.plugins }
      end
    end

    describe "#commandline_options"

    context "plugin callbacks" do
      before do
        @base_plugin   = Class.new(Mint::Plugin)
        @first_plugin  = Class.new(@base_plugin)
        @second_plugin = Class.new(@base_plugin)

        @base_plugin.should_receive(:before_render).
          ordered.and_return('transformed by base')
        @first_plugin.should_receive(:before_render).
          ordered.and_return('transformed by first')
        @second_plugin.should_receive(:before_render).
          ordered.and_return('transformed by second')
      end

      describe "#before_render"
      describe "#after_render"
      describe "#after_mint" do
        # let(:document) { Document.new 'content.md' }
        #
        # it "allows changes to the document extension" do
          # Mint.should_call(:process_with).once.with(plugin)
          # Mint.publish!(document)
        # end
        # it "allows changes to the document type"
        # it "allows changes to the document structure"
        # it "allows changes to the document content"

        it "allows changes to final published document file"
        it "allows changes to final published style file"
        it "allows changes to final published document directory"
        it "allows changes to final published style directory"
        it "allows changes to final published style directory"
      end
    end
  end
end
