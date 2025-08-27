require "spec_helper"

module Mint
  describe Style do
    context "when it's created from a static file" do
      let(:style) { Style.new @static_style_file }
      subject { style }

      its(:destination) { is_expected.to be_nil }
      its(:destination_file) { is_expected.to eq("#{@tmp_dir}/static.css") }

      it { is_expected.to be_rendered }
      it "'renders' itself verbatim" do
        expect(style.render).to eq(File.read(@static_style_file))
      end
    end

    context "when it's created from a dynamic file" do
      let(:style) { Style.new @dynamic_style_file }
      subject { style }

      its(:destination) { is_expected.to be_nil }
      its(:destination_file) { is_expected.to eq("#{@tmp_dir}/dynamic.css") }

      it { is_expected.to be_rendered }
      it "renders itself from a templating language to CSS" do
        expect(style.render.gsub("\n", " ").strip).to eq(
          File.read(@static_style_file).gsub("\n", " ").strip)
      end
    end

    context "when it's created with a specified destination" do
      let(:style) { Style.new @static_style_file,
                    :destination => "destination" }
      subject { style }

      its(:destination) { is_expected.to eq("destination") }
      its(:destination_file) do
        is_expected.to eq("#{@tmp_dir}/destination/static.css")
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
    #      Mint.path_for_scope(:local) + "/templates/static_test/style.css"
    #  end
    # end

    context "when it's created from a dynamic template file" do
      let(:style) { Style.new(Mint.lookup_style("default")) }
      subject { style }

      it "has destination in user tmp directory" do
        expect(style.destination).to match(/\.config\/mint\/tmp$/)
      end
      it "has destination file in user tmp directory" do  
        expect(style.destination_file).to match(/\.config\/mint\/tmp\/style\.css$/)
      end
    end
  end
end
