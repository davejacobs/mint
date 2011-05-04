require 'spec_helper'

module Mint
  describe Resource do
    shared_examples_for "all resources" do
      subject { resource }

      its(:root_directory_path) do
        should == Pathname.new(resource.root_directory)
      end

      its(:source_file_path) do
        should == Pathname.new(resource.source_file)
      end

      its(:source_directory_path) do
        should == Pathname.new(resource.source_directory)
      end

      its(:destination_file_path) do
        should == Pathname.new(resource.destination_file)
      end

      its(:destination_directory_path) do
        should == Pathname.new(resource.destination_directory)
      end
    end

    context "when created with a relative path and no root" do
      let(:resource) { Resource.new @content_file }
      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test' }
      its(:source) { should == 'content.md' }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test' }

      it_should_behave_like "all resources"
    end

    context "when created with a relative path and absolute root" do
      let(:resource) { Resource.new @content_file,
                       :root => '/tmp/mint-test/alternative-root' }
      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test/alternative-root' }
      its(:source) { should == 'content.md' }

      its(:source_file) do
        should == '/tmp/mint-test/alternative-root/content.md'
      end

      its(:source_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination) { should be_nil }

      its(:destination_file) do
        should == '/tmp/mint-test/alternative-root/content.html'
      end

      its(:destination_directory) do
        should == '/tmp/mint-test/alternative-root'
      end

      it_should_behave_like "all resources"
    end

    context "when created with a relative path and absolute root" do
      let(:resource) { Resource.new "/tmp/mint-test/#{@content_file}" }
      subject { resource }
      
      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test' }
      its(:source) { should == '/tmp/mint-test/content.md' }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test' }

      it_should_behave_like "all resources"
    end

    # The root should *not* override a source file absolute path but
    # *should* affect the destination file path.
    context "when created with an absolute path and root" do
      let(:resource) { Resource.new '/tmp/mint-test/content.md',
                       :root => '/tmp/mint-test/alternative-root' }

      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test/alternative-root' }
      its(:source) { should == '/tmp/mint-test/content.md' }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:destination) { should be_nil }

      its(:destination_file) do
        should == '/tmp/mint-test/alternative-root/content.html'
      end

      its(:destination_directory) do
        should == '/tmp/mint-test/alternative-root'
      end

      it_should_behave_like "all resources"
    end

    context "when it's created with a block" do
      let(:resource) do
        Resource.new @content_file do |resource|
          resource.root = '/tmp/mint-test/alternative-root'
          resource.destination = 'destination'
        end
      end

      subject { resource }
      
      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test/alternative-root' }
      its(:source) { should == 'content.md' }

      its(:source_file) do
        should == '/tmp/mint-test/alternative-root/content.md'
      end

      its(:source_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination) { should == 'destination' }

      its(:destination_file) do
        should == '/tmp/mint-test/alternative-root/destination/content.html'
      end

      its(:destination_directory) do
        should == '/tmp/mint-test/alternative-root/destination'
      end

      it_should_behave_like "all resources"
    end
  end
end
