require 'spec_helper'

module Mint
  describe Style do
    context "when it's created from a static file" do
      let(:style) { Style.new @static_style_file }
      subject { style }

      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@tmp_dir}/static.css" }

      it { should_not be_rendered }
      it "'renders' itself verbatim" do
        style.render.should == File.read(@static_style_file)
      end
    end

    context "when it's created from a dynamic file" do
      let(:style) { Style.new @dynamic_style_file }
      subject { style }

      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@tmp_dir}/dynamic.css" }

      it { should be_rendered }
      it "renders itself from a templating language to Html" do
        style.render.gsub("\n", " ").should == 
          File.read(@static_style_file).gsub("\n", " ")
      end
    end

    context "when it's created with a specified destination" do
      let(:style) { Style.new @static_style_file,
                    :destination => 'destination' }
      subject { style }

      its(:destination) { should == 'destination' }
      its(:destination_file) do
        should == "#{@tmp_dir}/destination/static.css"
      end
    end

    # TODO: Create local-scope templates directory that I can test this with,
    # and use it to beef up other specs (like document_spec and mint_spec)
    # context "when it's created from a static template file" do
    #  let(:style) { Style.new(Mint.lookup_template(:static_test, :style)) }
    #  it "#destination" do
    #    style.destination.should be_nil
    #  end

    #  it "#destination_file" do
    #    style.destination_file.should == 
    #      Mint.path_for_scope(:local) + '/templates/static_test/style.css'
    #  end
    # end

    context "when it's created from a dynamic template file" do
      let(:style) { Style.new(Mint.lookup_template(:default, :style)) }
      subject { style }

      its(:destination) { should == 'css' }
      its(:destination_file) do
        should == "#{Mint.root}/config/templates/default/css/style.css"
      end
    end
  end
end
