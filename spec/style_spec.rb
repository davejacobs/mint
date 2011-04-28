require 'spec_helper'

module Mint
  describe Style do
    context "when it's created from a static file" do
      let(:style) { Style.new @static_style_file }

      it "#rendered?" do
        style.should_not be_rendered
      end

      it "#render" do
        style.render.should == File.read(@static_style_file)
      end

      it "#destination" do
        style.destination.should be_nil
      end

      it "#destination_file" do
        style.destination_file.should == '/tmp/mint-test/static.css'
      end
    end

    context "when it's created from a dynamic file" do
      let(:style) { Style.new @dynamic_style_file }

      it "#rendered?" do
        style.should be_rendered
      end

      it "#render" do
        style.render.gsub("\n", " ").should == 
          File.read(@static_style_file).gsub("\n", " ")
      end

      it "#destination" do
        style.destination.should be_nil
      end

      it "#destination_file" do
        style.destination_file.should == '/tmp/mint-test/dynamic.css'
      end
    end

    context "when it's created with a specified destination" do
      let(:style) { Style.new @static_style_file,
                    :destination => 'destination' }

      it "#destination" do
        style.destination.should == 'destination'
      end

      it "#destination_file" do
        style.destination_file.should == 
          '/tmp/mint-test/destination/static.css'
      end
    end

    # TODO: Create local-scope templates directory that I can test this with,
    # and use it to beef up other specs (like document_spec and mint_spec)
    context "when it's created from a static template file" do
    #  let(:style) { Style.new(Mint.lookup_template(:static_test, :style)) }
    #  it "#destination" do
    #    style.destination.should be_nil
    #  end

    #  it "#destination_file" do
    #    style.destination_file.should == 
    #      Mint.path_for_scope(:local) + '/templates/static_test/style.css'
    #  end
    end

    context "when it's created from a dynamic template file" do
      let(:style) { Style.new(Mint.lookup_template(:default, :style)) }
      it "#destination" do
        style.destination.should == 'css'
      end

      it "#destination_file" do
        style.destination_file.should == 
          Mint.root + '/templates/default/css/style.css'
      end
    end
  end
end
