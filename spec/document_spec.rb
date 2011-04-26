require 'spec_helper'

module Mint
  describe Document do
    shared_examples_for "all documents" do
      subject { document }

      # Re-test key methods defined in resource to make sure
      # they haven't changed. (We are not testing any logical derivatives
      # of #source, like #source_file_path. We just want to make sure
      # that these key values are being set and not changed.)

      its(:root) { should == @root }
      its(:destination) { should == @destination }
      its(:source) { should == @content_file }

      # We do have to test #style_destination derivatives because
      # they do not strictly delegate to #style.destination -- that is,
      # for some documents, they are not tied to the resource implementation
      # and so do not benefit from automatic virtual attributes like
      # #style_destination_file_path.

      its(:style_destination) { should == @style_destination }
      its(:style_destination_file_path) { should == Pathname.new(@style_destination_file) }
      its(:style_destination_file) { should == @style_destination_file }
      its(:style_destination_directory_path) { should == Pathname.new(@style_destination_directory) }
      its(:style_destination_directory) { should == @style_destination_directory }

      # We'll leave style generation tests to style_spec.rb, 
      # but we need to test layout and content generation (in a 
      # later context) because the layout needs to be injected 
      # with generated content.
      
      its(:layout) { should be_in_directory(@layout) }
      its(:style) { should be_in_directory(@style) }

      # Convenience methods
      
      it "#stylesheet" do
        relative_path = document.destination_file_path.
            relative_path_from(document.style_destination_file_path)

        document.stylesheet.should == relative_path.to_s
      end

      it "#inline_style" do
        pending "the suite doesn't yet support this use case"
        document.inline_style.should be_nil
      end

      its(:content) { should =~ /<p>This is just a test.<\/p>/ }

      # Render output

      it "renders its layout, injecting content inside" do
        document.render.should =~ 
          /.*<html>.*#{document.content}.*<\/html>.*/m
      end

      it "links to its stylesheet" do 
        document.render.should =~ /#{document.stylesheet}/
      end

      # Mint output

      it "writes its rendered style to #style_destination_file" do
        document.mint
        document.style_destination_file_path.should exist
      end

      it "writes its rendered layout and content to #destination_file" do
        document.mint
        document.destination_file_path.should exist
        content = File.read document.destination_file
        content.should == document.render
      end
    end

    context "when it's created with default options" do
      let(:document) { Document.new @content_file }

      before do
        @root                        = nil
        @destination                 = nil
        @style_destination           = nil
        @style_destination_file      = Mint.root + '/templates/default/css/style.css'
        @style_destination_directory = Mint.root + '/templates/default/css'
        @style                       = nil
        @layout                      = nil
      end

      it_should_behave_like "all documents"
    end

    # We need to test explicit directories even though they are tested in
    # resource_spec.rb because we want to make sure that all relative paths
    # work correctly in the context of a document. This includes relative
    # paths like we find in the #stylesheet helper.
    context "when it's created with explicit destination directories" do
      let(:document) { Document.new @content_file,
                       :destination => 'destination',
                       :style_destination => 'styles' }

      before do
        @root =                      nil
        @destination                 = 'destination'
        @style_destination           = 'styles'
        @style_destination_file      = Dir.getwd + '/destination/styles/style.css'
        @style_destination_directory = Dir.getwd + '/destination/styles'
        @style                       = 'default'
        @layout                      = 'default'
      end

      it_should_behave_like "all documents"
    end

    context "when it's created with an explicit root" do 
      let(:document) { Document.new @content_file,
                       :root => '/tmp/mint-test/alternative-root' }

      before do
        @root                        = '/tmp/mint-test/alternative-root'
        @destination                 = nil
        @style_destination           = nil
        @style_destination_file      = Mint.root + '/templates/default/css/style.css'
        @style_destination_directory = Mint.root + '/templates/default/css'
        @style                       = 'default'
        @layout                      = 'default'
      end

      it_should_behave_like "all documents"
    end

    context "when it is created with a block" do
      let(:document) do
        Document.new @content_file do |doc|
          doc.root              = '/tmp/mint-test/alternative-root'
          doc.destination       = 'destination'
          doc.style_destination = 'styles'
          doc.layout            = 'pro'
          doc.style             = 'pro'
        end
      end

      before do
        @root                        = '/tmp/mint-test/alternative-root'
        @destination                 = 'destination'
        @style_destination           = 'styles'
        @style_destination_file = 
          '/tmp/mint-test/alternative-root/destination/styles/style.css'
        @style_destination_directory = 
          '/tmp/mint-test/alternative-root/destination/styles'
        @style                       = 'pro'
        @layout                      = 'pro'
      end

      it_should_behave_like "all documents"
    end
  end
end
