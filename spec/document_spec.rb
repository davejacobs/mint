require 'spec_helper'

module Mint
  describe Document do
    before { @tmp_dir = Dir.getwd }

    # We're not going to re-test derivative methods like source_file_path
    # or root_directory. resource_spec.rb tells us that if the master
    # values hold true, then their derivatives will be what we expect, as well.
    # We do have to test #style_destination derivatives. Those aren't
    # covered by resource_spec.rb.
    shared_examples_for "all documents" do
      # Convenience methods
      
      describe "#stylesheet" do
        it "returns a relative path to the document's rendered stylesheet from its rendered content file" do
          relative_path = document.destination_file_path.
              relative_path_from(document.style_destination_file_path)

          document.stylesheet.should == relative_path.to_s
        end
      end

      # style_spec.rb ensures that our style generation goes as planned
      # However, we need to test layout generation because it should now
      # include our content
      #
      # This test doesn't cover any plugin transformations. Those
      # transformations are covered in the Plugin spec.
      its(:content) { should =~ /<p>This is just a test.<\/p>/ }

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
        should == Mint.root + '/templates/default/css/style.css'
      end

      its(:style_destination_directory) do 
        should == Mint.root + '/templates/default/css'
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('default') }
      its(:style) { should be_in_directory('default') }

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
        should == Mint.root + '/templates/default/css/style.css'
      end

      its(:style_destination_directory) do
        should == Mint.root + '/templates/default/css'
      end

      its(:style_destination_file_path) do
        should == Pathname.new(document.style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(document.style_destination_directory)
      end

      its(:layout) { should be_in_directory('default') }
      its(:style) { should be_in_directory('default') }

      it_should_behave_like "all documents"
    end

    context "when it is created with a block" do
      let(:document) do
        Document.new @content_file do |doc|
          doc.root              = "#{@tmp_dir}/alternative-root"
          doc.destination       = 'destination'
          doc.style_destination = 'styles'
          doc.layout            = 'pro'
          doc.style             = 'pro'
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

      its(:layout) { should be_in_directory('pro') }
      its(:style) { should be_in_directory('pro') }

      it_should_behave_like "all documents"
    end
  end
end
