require 'spec_helper'
require 'fakefs/spec_helpers'
require 'fakefs/safe'

module Mint
  describe Document do
    before(:all) do
      @old_dir = Dir.getwd
      Dir.chdir 'tmp'
    end

    before(:each) do 
      @file = 'content.md'
      @layout_file = 'local.haml'
      @style_file = 'local.css'

      @content = <<-HERE.gsub(/^\s*/, '')
          Header
          ------

          This is just a test.
      HERE

      @layout = <<-HERE.gsub(/^\s*/, '')
          !!!
          %html
            %head
            %body= content
      HERE

      @style = 'body { font-size: 16px }'

      File.open @file, 'w' do |f|
        f << @content
      end

      File.open @layout_file, 'w' do |f|
        f << @layout
      end

      File.open @style_file, 'w' do |f|
        f << @style
      end
    end

    after(:all) do
      File.delete @content
      File.delete @layout_file
      File.delete @style_file
      Dir.chdir @old_dir
    end

    shared_examples_for "all documents" do
      it "loads content as its source" do
        @document.source.to_s.should == 'content.md'
      end

      it "guesses its name from the source" do
        @document.name.to_s.should =~ /content/
      end

      it "renders its content" do
        @document.content.should =~ /<p>This is just a test.<\/p>/
      end

      it "renders its layout, injecting content inside" do
        @document.render.should =~ /.*<html>.*<\/html>.*/m
        @document.render.should =~ /<p>This is just a test.<\/p>/
      end

      it "writes its rendered layout + content to its destination directory" do
        @document.mint
        file = Pathname.getwd + (@document.destination || '') + @document.name
        file.exist?.should == true
      end
    end

    shared_examples_for "documents with a static stylesheet" do
      it "does not render its style" do
        @document.style.needs_rendering?.should == false
      end
    end

    shared_examples_for "documents with a dynamic stylesheet" do
      it "renders its style" do
        @document.style.needs_rendering?.should == true
      end
    end

    shared_examples_for "documents with the default template" do
      it "chooses the default layout" do
        @document.layout.should be_in_directory('default')
      end

      it "chooses the default style" do
        @document.style.should be_in_directory('default')
      end
    end

    shared_examples_for "documents with the pro template" do
      it "chooses the pro layout" do
        @document.layout.should be_in_directory('pro')
      end

      it "chooses the pro style" do
        @document.style.should be_in_directory('pro')
      end
    end

    shared_examples_for "documents with the local template" do
      it "chooses the local layout" do
        @document.layout.name.to_s.should =~ /local/
        @document.layout.source.to_s.should == 'local.haml'
      end

      it "chooses the local style" do
        @document.style.name.to_s.should =~ /local/
        @document.style.source.to_s.should == 'local.css'
      end
    end

    shared_examples_for "documents without explicit directories" do
      it "does not have a nested destination directory" do
        @document.destination.should be_nil
      end

      it "sets the style's current directory as its style destination" do
        @document.style_destination.should be_nil
      end
    end

    shared_examples_for "documents with explicit directories" do
      it "has a nested destination directory" do
        @document.destination.to_s.should == 'destination'
      end

      it "sets the destination directory as its style destination" do
        @document.style_destination.to_s.should == 'styles'
      end
    end

    context "when it's created without explicit options" do
      before(:each) do
        @document = Document.new @file
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the default template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created inline with named layouts and styles" do
      before(:each) do
        @document = Document.new @file, :layout => 'pro', :style => 'pro'
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the pro template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created inline with local layouts and styles" do
      before(:each) do
        @document = Document.new @file, :layout => 'local.haml', 
          :style => 'local.css'
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the local template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a static stylesheet"
    end

    context "when it's created with a template" do
      before(:each) do
        @document = Document.new @file, :template => 'pro'
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the pro template"
      it_behaves_like "documents without explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created with a non-default destinations" do
      before(:each) do
        @document = Document.new @file, :root => 'root',
          :destination => 'destination', :style_destination => 'styles'
      end

      it_behaves_like "all documents"
      it_behaves_like "documents with the default template"
      it_behaves_like "documents with explicit directories"
      it_behaves_like "documents with a dynamic stylesheet"
    end

    context "when it's created with a block" do
      before(:each) do
        @document = Document.new @file do |document|
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
  end
end
