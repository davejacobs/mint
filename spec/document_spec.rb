require 'spec_helper'

FakeFS do
  module Mint
    describe Document do
      before(:each) do 
        @file = 'content.md'
        @layout_file = 'local.haml'
        @style_file = 'local.sass'

        File.open @file, 'w' do |f|
          f << <<-HERE.gsub(/^\s*/, '')
            Header
            ------

            This is just a test.
          HERE
        end

        File.open @layout_file, 'w' do |f|
          f << <<-HERE.gsub(/^\s*/, '')
            !!!
            %html
              %head
              %body= content
          HERE
        end

        File.open @style_file, 'w' do |f|
          f << 'body { font-size: 16px }'
        end
      end

      shared_examples_for "all documents" do
        it "loads content as its source" do
          @document.source.to_s.should == 'content.md'
        end

        it "guesses its name from the source" do
          @document.name.to_s.should =~ /content/
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
        it "chooses the 'local' layout" do
          @document.layout.name.to_s.should =~ /local/
          @document.layout.source.to_s.should == @layout_file
        end

        it "chooses the 'local' style" do
          @document.style.name.to_s.should =~ /local/
          @document.style.source.to_s.should == @style_file
        end
      end

      shared_examples_for "documents without explicit directories" do
        it "sets the root directory as its destination directory" do
          @document.destination.to_s.should == ''
        end

        it "sets the style's current directory as the style's destination directory" do
          @document.style_destination.should == 
            @document.style.source.dirname.expand_path
        end
      end

      shared_examples_for "documents with explicit directories" do
        it "sets the root directory as its destination directory" do
          @document.destination.to_s.should == 'destination'
        end

        it "sets the destination directory as its style destination directory" do
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
      end

      context "when it's created inline with named layouts and styles" do
        before(:each) do
          @document = Document.new @file, :layout => 'pro', :style => 'pro'
        end

        it_behaves_like "all documents"
        it_behaves_like "documents with the pro template"
        it_behaves_like "documents without explicit directories"
      end

      context "when it's created inline with local layouts and styles" do
        before(:each) do
          @document = Document.new @file, :layout => 'local.haml', 
            :style => 'local.sass'
        end

        it_behaves_like "all documents"
        it_behaves_like "documents with the local template"
        it_behaves_like "documents without explicit directories"
      end

      context "when it's created with a template" do
        before(:each) do
          @document = Document.new @file, :template => 'pro'
        end

        it_behaves_like "all documents"
        it_behaves_like "documents with the pro template"
        it_behaves_like "documents without explicit directories"
      end

      context "when it's created with a non-default destinations" do
        before(:each) do
          @document = Document.new @file, :root => 'root',
            :destination => 'destination', :style_destination => 'styles'
        end

        it_behaves_like "all documents"
        it_behaves_like "documents with the default template"
        it_behaves_like "documents with explicit directories"
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
      end
    end
  end
end
