require "spec_helper"

module Mint
  describe Document do
    # We're not going to re-test derivative methods like source_file_path
    # or root_directory. resource_spec.rb tells us that if the master
    # values hold true, then their derivatives will be what we expect, as well.
    # We do have to test #style_destination derivatives. Those aren't
    # covered by resource_spec.rb.
    shared_examples_for "all documents" do
      # style_spec.rb ensures that our style generation goes as planned
      # However, we need to test layout generation because it should now
      # include our content
      #
      # This test doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      its(:content) { is_expected.to match(/<p>This is just a test.<\/p>/) }
      its(:metadata) { is_expected.to eq({ "metadata" =>  true }) }

      # Render output

      # This test doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      it "renders its layout, injecting content inside" do
        expect(document.render).to include(document.content)
        expect(document.render).to include("<html")
        expect(document.render).to include("</html>")
      end

      it "includes its stylesheet inline" do 
        expect(document.render).to include("<style>")
        expect(document.render).to include("</style>")
      end

      # Mint output

      # These tests doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      it "writes its rendered style to #style_destination_file" do
        document.publish!
        expect(document.style_destination_file_path).to exist
      end

      it "writes its rendered layout and content to #destination_file" do
        document.publish!
        expect(document.destination_file_path).to exist
        content = File.read document.destination_file
        expect(content).to eq(document.render)
      end
    end

    context "when it's created with default options" do
      let(:document) { Document.new @content_file }

      subject { document }
      its(:root) { is_expected.to eq(@tmp_dir) }
      its(:destination) { is_expected.to be_nil }
      its(:source) { is_expected.to eq("content.md") }
      its(:style_destination) { is_expected.to be_nil }

      it "has a style destination file in user tmp directory" do
        expect(document.style_destination_file).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it "has a style destination directory in user tmp directory" do
        expect(document.style_destination_directory).to match(/\.config\/mint\/tmp$/)
      end

      its(:style_destination_file_path) do
        is_expected.to eq(Pathname.new(document.style_destination_file))
      end

      its(:style_destination_directory_path) do
        is_expected.to eq(Pathname.new(document.style_destination_directory))
      end

      its(:layout) { is_expected.to be_in_directory("default") }
      its(:style) { is_expected.to be_in_directory("default") }

      it "has a stylesheet path relative to user tmp directory" do
        expect(document.stylesheet).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it_should_behave_like "all documents"
    end

    context "when it's created with explicit destination directories" do
      let(:document) { Document.new @content_file,
                       :destination => "destination",
                       :style_destination => "styles" }

      subject { document }
      its(:root) { is_expected.to eq(@tmp_dir) }
      its(:destination) { is_expected.to eq("destination") }
      its(:source) { is_expected.to eq("content.md") }
      its(:style_destination) { is_expected.to eq("styles") }

      its(:style_destination_file) do
        is_expected.to eq("#{@tmp_dir}/destination/styles/style.css")
      end

      its(:style_destination_directory) do
        is_expected.to eq("#{@tmp_dir}/destination/styles")
      end

      its(:style_destination_file_path) do
        is_expected.to eq(Pathname.new(document.style_destination_file))
      end

      its(:style_destination_directory_path) do
        is_expected.to eq(Pathname.new(document.style_destination_directory))
      end

      its(:layout) { is_expected.to be_in_directory("default") }
      its(:style) { is_expected.to be_in_directory("default") }

      it "has a stylesheet path relative to user tmp directory" do
        expect(document.stylesheet).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it_should_behave_like "all documents"
    end

    context "when it's created with an explicit root" do 
      let(:document) { Document.new @content_file,
                       :root => "#{@tmp_dir}/alternative-root" }

      subject { document }
      its(:root) { is_expected.to eq("#{@tmp_dir}/alternative-root") }
      it "preserves folder structure" do
        expect(document.destination).to be_present
      end
      its(:source) { is_expected.to eq("content.md") }
      its(:style_destination) { is_expected.to be_nil }

      it "has a style destination file in user tmp directory" do
        expect(document.style_destination_file).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it "has a style destination directory in user tmp directory" do
        expect(document.style_destination_directory).to match(/\.config\/mint\/tmp$/)
      end

      its(:style_destination_file_path) do
        is_expected.to eq(Pathname.new(document.style_destination_file))
      end

      its(:style_destination_directory_path) do
        is_expected.to eq(Pathname.new(document.style_destination_directory))
      end

      its(:layout) { is_expected.to be_in_directory("default") }
      its(:style) { is_expected.to be_in_directory("default") }

      it "has a stylesheet path relative to user tmp directory" do
        expect(document.stylesheet).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it_should_behave_like "all documents"
    end

    context "when it is created with a block" do
      let(:document) do
        Document.new @content_file do |doc|
          doc.root              = "#{@tmp_dir}/alternative-root"
          doc.destination       = "destination"
          doc.style_destination = "styles"
          doc.layout            = "zen"
          doc.style             = "zen"
        end
      end

      subject { document }
      its(:root) { is_expected.to eq("#{@tmp_dir}/alternative-root") }
      its(:destination) { is_expected.to eq("destination") }
      its(:source) { is_expected.to eq("content.md") }
      its(:style_destination) { is_expected.to eq("styles") }

      its(:style_destination_file) do
        is_expected.to eq("#{@tmp_dir}/alternative-root/destination/styles/style.css")
      end

      its(:style_destination_directory) do
        is_expected.to eq("#{@tmp_dir}/alternative-root/destination/styles")
      end

      its(:style_destination_file_path) do
        is_expected.to eq(Pathname.new(document.style_destination_file))
      end

      its(:style_destination_directory_path) do
        is_expected.to eq(Pathname.new(document.style_destination_directory))
      end

      its(:layout) { is_expected.to be_in_directory("zen") }
      its(:style) { is_expected.to be_in_directory("zen") }

      it "has a stylesheet path relative to user tmp directory" do
        expect(document.stylesheet).to match(/\.config\/mint\/tmp\/style\.css$/)
      end

      it_should_behave_like "all documents"
    end

    context "when dealing with metadata" do
      let(:text) { "metadata: true\n\nReal text" }
      describe ".metadata_chunk" do
        it "extracts, but does not parse, metadata from text" do
          expect(Document.metadata_chunk(text)).to eq("metadata: true")
        end
      end

      describe ".metadata_from" do
        it "parses a documents metadata if present" do
          expect(Document.metadata_from(text)).to eq({ "metadata" => true })
        end

        it "returns the empty string if a document has bad/no metadata" do
          expect(Document.metadata_from("No metadata here")).to eq({})
        end

        it "handles a non-simple string that is also not YAML" do
          expect(Document.metadata_from("# Non-simple string")).to eq({})
        end
      end

      describe ".parse_metadata_from" do
        it "separates text from its metadata if present" do
          expect(Document.parse_metadata_from(text)).to eq(
            [{ "metadata" => true }, "Real text"])
        end

        it "returns the entire text if no metadata is found" do
          expect(Document.parse_metadata_from("No metadata here")).to eq(
            [{}, "No metadata here"])
        end
      end
    end
  end
end
