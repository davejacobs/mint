require 'spec_helper'

module Mint
  describe Document do
    shared_examples_for "all documents" do
      # Re-test key methods defined in resource to make sure
      # they haven't changed. (We are not testing any logical derivatives
      # of #source, like #source_file_path. We just want to make sure
      # that these key values are being set and not changed.)

      it "#root" do
        document.root.should == @root
      end

      it "#destination" do
        document.destination.should == @destination
      end
      
      it "#source" do
        document.source.should == @content_file
      end

      # We do have to test #style_destination derivatives because
      # they do not strictly delegate to #style.destination -- that is,
      # for some documents, they are not tied to the resource implementation
      # and so do not benefit from automatic virtual attributes like
      # #style_destination_file_path.

      it "#style_destination" do
        document.style_destination.should == @style_destination
      end

      it "#style_destination_file_path" do
        document.style_destination_file_path.should ==
          Pathname.new(@style_destination_file)

        # if document.style_destination
        #   path = Pathname.new document.style_destination
        #   dir = path.absolute? ?
        #     path : document.destination_directory_path + path
        #   document.style_destination_file_path.should ==
        #     dir + document.style.name
        # else
        #   document.style_destination_file_path.should ==
        #     document.style.destination_file_path
        # end
      end

      it "#style_destination_file" do
        document.style_destination_file.should ==
          document.style_destination_file_path.to_s
      end

      it "#style_destination_directory_path" do
        document.style_destination_directory_path.should ==
          Pathname.new(document.style_destination_file).dirname
      end

      it "#style_destination_directory" do
        document.style_destination_directory.should ==
          document.style_destination_directory_path.to_s
      end

      # Ensure that the document is choosing the right layout and
      # style templates. We'll leave style generation tests to
      # style_spec.rb, but we need to test layout and content
      # generation (in a later context) because the layout
      # needs to be injected with generated content.

      it "#layout" do
        document.layout.should be_in_directory(@layout)
      end

      it "#style" do
        document.style.should be_in_directory(@style)
      end

      # Convenience methods
      
      it "#stylesheet" do
        relative_path = 
          document.destination_file_path.
            relative_path_from(document.style_destination_file_path)

        document.stylesheet.should == relative_path.to_s
      end

      it "#inline_style" do
        pending "the suite doesn't yet support this use case"
        document.inline_style.should be_nil
      end

      it "#content" do
        document.content.should =~ /<p>This is just a test.<\/p>/
      end

      it "renders its layout, injecting content inside" do
        document.render.should =~ 
          /.*<html>.*#{document.content}.*<\/html>.*/m
      end

      it "links to its stylesheet" do 
        document.render.should =~ /#{document.stylesheet}/
      end

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
        # These are the expectations that the "all documents"
        # shared example will use to validate this example. I'm 
        # not going to reuse these variables to instantiate document
        # because in some cases, we don't want the same value back in
        # our tests, and I want to maintain a clear separation between
        # test expectations and test input.
        @root = Dir.getwd
        @destination = nil
        @style_destination = nil
        @style_destination_file = Mint.root + '/templates/default/css/style.css'
        @style = nil
        @layout = nil
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
        # Expectations for tests:
        @root = Dir.getwd
        @destination = 'destination'
        @style_destination = 'styles'
        @style_destination_file = Dir.getwd + '/destination/styles/style.css'
        @style = 'default'
        @layout = 'default'
      end

      it_should_behave_like "all documents"
    end

    context "when it's created with an explicit root" do 
      let(:document) { Document.new @content_file,
                       :root => '/tmp/mint-test/alternative-root' }

      before do
        # Expectations for tests:
        @root = '/tmp/mint-test/alternative-root'
        @destination = nil
        @style_destination = nil
        @style_destination_file = (Mint.root + '/templates/default/css/style.css')
        @style = 'default'
        @layout = 'default'
      end

      it_should_behave_like "all documents"
    end

    context "when it is created with a block" do
      before do
        # Expectations for tests:
        @root = '/tmp/mint-test/alternative-root'
        @destination = 'destination'
        @style_destination = 'styles'
        @style_destination_file = 
          '/tmp/mint-test/alternative-root/destination/styles/style.css'
        @style = 'pro'
        @layout = 'pro'
      end

      let(:document) do
        Document.new @content_file do |document|
          document.root = '/tmp/mint-test/alternative-root'
          document.destination = 'destination'
          document.style_destination = 'styles'
          document.layout = 'pro'
          document.style = 'pro'
        end
      end

      it_should_behave_like "all documents"
    end
  end
end
