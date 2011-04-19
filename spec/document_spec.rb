require 'spec_helper'

module Mint
  describe Document do
    before(:all) do
      @old_dir = Dir.getwd
      Dir.chdir 'tmp'
    end

    before do 
      @content_file = 'content.md'
      @layout_file = 'local.haml'
      @style_file = 'local.css'

      @content = <<-HERE
Header
------

This is just a test.
      HERE

      @layout = <<-HERE
!!!
%html
  %head
  %body= content
      HERE

      @style = 'body { font-size: 16px }'

      File.open @content_file, 'w' do |f|
        f << @content
      end

      File.open @layout_file, 'w' do |f|
        f << @layout
      end

      File.open @style_file, 'w' do |f|
        f << @style
      end
    end

    after do
      File.delete @content_file
      File.delete @layout_file
      File.delete @style_file
    end

    after(:all) do
      Dir.chdir @old_dir
    end

    shared_examples_for "all documents" do
      it "loads content as its source" do
        document.source.to_s.should == 'content.md'
      end

      it "guesses its name from the source" do
        document.name.to_s.should =~ /content/
      end

      it "renders its content" do
        document.content.should =~ /<p>This is just a test.<\/p>/
      end

      it "renders its layout, injecting content inside" do
        document.render.should =~ 
          /.*<html>.*<p>This is just a test.<\/p>.*<\/html>.*/m
      end

      it "creates a named output file in its specified destination directory" do
        file = Pathname.getwd + (document.destination || '') + document.name
        file.should exist
      end

      it "writes its rendered layout and content to that output file" do
        document.mint
        file = Pathname.getwd + (document.destination || '') + document.name
        content = File.read file
        content.should =~ /.*<html>.*<p>This is just a test.<\/p>.*<\/html>.*/m
      end
    end

    shared_examples_for "documents with a static stylesheet" do
      it "knows not to render its style" do
        document.style.need_rendering?.should == false
      end
      
      it "does not render or write its style"
    end

    shared_examples_for "documents with a dynamic stylesheet" do
      it "knows to render its style" do
        document.style.need_rendering?.should == true
      end

      it "writes its rendered style into its style_destination"
    end

    shared_examples_for "documents with the default template" do
      it "chooses the default layout" do
        document.layout.should be_in_directory('default')
      end

      it "chooses the default style" do
        document.style.should be_in_directory('default')
      end
    end

    shared_examples_for "documents with the pro template" do
      it "chooses the pro layout" do
        document.layout.should be_in_directory('pro')
      end

      it "chooses the pro style" do
        document.style.should be_in_directory('pro')
      end
    end

    shared_examples_for "documents with the local template" do
      it "chooses the local layout" do
        document.layout.name.to_s.should =~ /local/
        document.layout.source.to_s.should == 'local.haml'
      end

      it "chooses the local style" do
        document.style.name.to_s.should =~ /local/
        document.style.source.to_s.should == 'local.css'
      end
    end

    shared_examples_for "documents without explicit directories" do
      it "does not have a nested destination directory" do
        document.destination.should be_nil
      end

      it "sets the style's current directory as its style destination" do
        document.style_destination.should be_nil
      end
    end

    shared_examples_for "documents with explicit directories" do
      it "has a nested destination directory" do
        document.destination.to_s.should == 'destination'
      end

      it "sets the destination directory as its style destination" do
        document.style_destination.to_s.should == 'styles'
      end
    end

    context "when it's created without explicit options" do
      let(:document) { Document.new @content_file }

      it_behaves_like "all documents"
      it_behaves_like "documents with the default template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created inline with named layouts and styles" do
      let(:document) { Document.new @content_file, 
                       :layout => 'pro', :style => 'pro' }

      it_behaves_like "all documents"
      it_behaves_like "documents with the pro template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created inline with local layouts and styles" do
      let(:document) { Document.new @content_file, 
                       :layout => 'local.haml', :style => 'local.css' }

      it_behaves_like "all documents"
      it_behaves_like "documents with the local template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a static stylesheet"
    end

    context "when it's created with a template" do
      let(:document) { Document.new @content_file, :template => 'pro' }

      it_behaves_like "all documents"
      it_behaves_like "documents with the pro template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created with a non-default destinations" do
      let(:document) { Document.new @content_file, 
                       :root => 'root', :destination => 'destination',
                       :style_destination => 'styles' }

      it_behaves_like "all documents"
      it_behaves_like "documents with the default template"
      it_behaves_like "documents with explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created with a block" do
      let(:document) do
        Document.new @content_file do |document|
          document.destination = 'destination'
          document.style_destination = 'styles'
          document.layout = 'pro'
          document.style = 'pro'
        end
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the pro template"
      it_behaves_like "documents with explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created with an existing layout"
    context "when it's created with an existnig style"
  end
end
