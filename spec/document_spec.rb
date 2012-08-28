require 'spec_helper'

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
      its(:content) { should =~ /<p>This is just a test.<\/p>/ }
      its(:metadata) { should == { 'metadata' =>  true } }

      # Render output

      # This test doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      it "renders its layout, injecting content inside" do
        document.render.should =~ 
          /.*<html>.*#{document.content}.*<\/html>.*/m
      end

      it "links to its stylesheet" do 
        document.render.should =~ /#{document.stylesheet}/
      end

      # Mint output

      # These tests doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      it "writes its rendered style to #style_destination_file" do
        document.publish!
        document.style_destination_file_path.should exist
      end

      it "writes its rendered layout and content to #destination_file" do
        document.publish!
        document.destination_file_path.should exist
        content = File.read document.destination_file
        content.should == document.render
      end
    end

    context "when it's created with default options" do
      let(:document) { Document.new @content_file }

      subject { document }
      its(:root) { should == @tmp_dir }
      its(:destination) { should be_nil }
      its(:source) { should == 'content.md' }
      its(:style_destination) { should be_nil }

      its(:style_destination_file) do
        should == Mint.root + '/config/templates/default/css/style.css'
      end

      its(:style_destination_directory) do 
        should == Mint.root + '/config/templates/default/css'
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('default') }
      its(:style) { should be_in_directory('default') }

      its(:stylesheet) { should == Mint.root + '/config/templates/default/css/style.css' }

      it_should_behave_like "all documents"
    end

    context "when it's created with explicit destination directories" do
      let(:document) { Document.new @content_file,
                       :destination => 'destination',
                       :style_destination => 'styles' }

      subject { document }
      its(:root) { should == @tmp_dir }
      its(:destination) { should == 'destination' }
      its(:source) { should == 'content.md' }
      its(:style_destination) { should == 'styles' }

      its(:style_destination_file) do
        should == "#{@tmp_dir}/destination/styles/style.css"
      end

      its(:style_destination_directory) do
        should == "#{@tmp_dir}/destination/styles"
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('default') }
      its(:style) { should be_in_directory('default') }

      its(:stylesheet) { should == 'styles/style.css' }

      it_should_behave_like "all documents"
    end

    context "when it's created with an explicit root" do 
      let(:document) { Document.new @content_file,
                       :root => "#{@tmp_dir}/alternative-root" }

      subject { document }
      its(:root) { should == "#{@tmp_dir}/alternative-root" }
      its(:destination) { should be_nil }
      its(:source) { should == 'content.md' }
      its(:style_destination) { should be_nil }

      its(:style_destination_file) do
        should == Mint.root + '/config/templates/default/css/style.css'
      end

      its(:style_destination_directory) do
        should == Mint.root + '/config/templates/default/css'
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('default') }
      its(:style) { should be_in_directory('default') }

      its(:stylesheet) { should == Mint.root + '/config/templates/default/css/style.css' }

      it_should_behave_like "all documents"
    end

    context "when it is created with a block" do
      let(:document) do
        Document.new @content_file do |doc|
          doc.root              = "#{@tmp_dir}/alternative-root"
          doc.destination       = 'destination'
          doc.style_destination = 'styles'
          doc.layout            = 'zen'
          doc.style             = 'zen'
        end
      end

      subject { document }
      its(:root) { should == "#{@tmp_dir}/alternative-root" }
      its(:destination) { should == 'destination' }
      its(:source) { should == 'content.md' }
      its(:style_destination) { should == 'styles' }

      its(:style_destination_file) do
        should == "#{@tmp_dir}/alternative-root/destination/styles/style.css"
      end

      its(:style_destination_directory) do
        should == "#{@tmp_dir}/alternative-root/destination/styles"
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('zen') }
      its(:style) { should be_in_directory('zen') }

      its(:stylesheet) { should == 'styles/style.css' }

      it_should_behave_like "all documents"
    end

    context "when dealing with metadata" do
      let(:text) { "metadata: true\n\nReal text" }
      describe ".metadata_chunk" do
        it "extracts, but does not parse, metadata from text" do
          Document.metadata_chunk(text).should == 'metadata: true'
        end
      end

      describe ".metadata_from" do
        it "parses a documents metadata if present" do
          Document.metadata_from(text).should == { 'metadata' => true }
        end

        it "returns the empty string if a document has bad/no metadata" do
          Document.metadata_from('No metadata here').should == {}
        end
      end

      describe ".parse_metadata_from" do
        it "separates text from its metadata if present" do
          Document.parse_metadata_from(text).should ==
            [{ 'metadata' => true }, 'Real text']
        end

        it "returns the entire text if no metadata is found" do
          Document.parse_metadata_from('No metadata here').should ==
            [{}, 'No metadata here']
        end
      end
    end
  end
end
