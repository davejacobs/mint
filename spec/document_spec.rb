require 'spec_helper'

module Mint
  describe Document do
    shared_examples_for "all documents" do
      subject { document }

      # resource_spec.rb tells us that if these hold true, then their
      # derivatives (root_directory, source_file_path, etc.) will be what we
      # expect, as well.
      its(:root) { should == @root }
      its(:destination) { should == @destination }
      its(:source) { should == @content_file }

      # We do have to test #style_destination derivatives. Those aren't
      # included in resource_spec.rb.
      its(:style_destination) { should == @style_destination }
      its(:style_destination_file) { should == @style_destination_file }
      its(:style_destination_directory) { should == @style_destination_directory }

      its(:style_destination_file_path) do
        should == Pathname.new(@style_destination_file)
      end

      its(:style_destination_directory_path) do
        should == Pathname.new(@style_destination_directory)
      end

      its(:layout) { should be_in_directory(@layout) }
      its(:style) { should be_in_directory(@style) }

      # Convenience methods
      
      it "#stylesheet" do
        relative_path = document.destination_file_path.
            relative_path_from(document.style_destination_file_path)

        document.stylesheet.should == relative_path.to_s
      end

      # style_spec.rb ensures that our style generation goes as planned
      # However, we need to test layout generation because it should now
      # include our content
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
