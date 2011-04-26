require 'spec_helper'

# Current problems to think about:
#
# 1. How flexible should my input be? Does it make sense for a source
#    to have an explicit root? Or should it either be judged based on
#    the current working directory OR the path of the absolute source
#    name?
#
# 2. Where should I handle the root? Should each resource have its own
#    root? If so, what happens if Document has a different source or
#    destination root? I should probably draw all of this out.
module Mint
  describe Resource do
    shared_examples_for "all resources" do
      subject { resource }
      its(:name)                       { should == @name }
      its(:root)                       { should == @root }
      its(:root_directory_path)        { should == Pathname.new(@root_directory) }
      its(:source)                     { should == @source }
      its(:source_file_path)           { should == Pathname.new(@source_file) }
      its(:source_file)                { should == @source_file }
      its(:source_directory_path)      { should == Pathname.new(@source_directory) }
      its(:source_directory)           { should == @source_directory }
      its(:destination)                { should == @destination }
      its(:destination_file_path)      { should == Pathname.new(@destination_file) }
      its(:destination_file)           { should == @destination_file }
      its(:destination_directory_path) { should == Pathname.new(@destination_directory) }
      its(:destination_directory)      { should == @destination_directory }
    end

    context "when created with a relative path and no root" do
      before do
        @name                  = 'content.html'
        @root                  = nil
        @root_directory        = '/tmp/mint-test'
        @source                = 'content.md'
        @source_file           = '/tmp/mint-test/content.md'
        @source_directory      = '/tmp/mint-test'
        @destinaton            = nil
        @destination_file      = '/tmp/mint-test/content.html'
        @destination_directory = '/tmp/mint-test'
      end

      let(:resource) { Resource.new @content_file }
      it_behaves_like "all resources"
    end

    context "when created with a relative path and absolute root" do
      before do
        # Expectations
        @name                  = 'content.html'
        @root                  = '/tmp/mint-test/alternative-root'
        @root_directory        = '/tmp/mint-test/alternative-root'
        @source                = 'content.md'
        @source_file           = '/tmp/mint-test/alternative-root/content.md'
        @source_directory      = '/tmp/mint-test/alternative-root'
        @destinaton            = nil
        @destination_file      = '/tmp/mint-test/alternative-root/content.html'
        @destination_directory = '/tmp/mint-test/alternative-root'
      end

      let(:resource) { Resource.new @content_file, 
                       :root => '/tmp/mint-test/alternative-root' }

      it_behaves_like "all resources"
    end

    context "when created with an absolute path and no root" do
      before do
        @name                  = 'content.html'
        @root                  = nil
        @root_directory        = '/tmp/mint-test'
        @root_directory        = '/tmp/mint-test'
        @source                = '/tmp/mint-test/content.md'
        @source_file           = '/tmp/mint-test/content.md'
        @source_directory      = '/tmp/mint-test'
        @destinaton            = nil
        @destination_file      = '/tmp/mint-test/content.html'
        @destination_directory = '/tmp/mint-test'
      end

      let(:resource) { Resource.new '/tmp/mint-test/content.md' }
      it_behaves_like "all resources"
    end

    # The root should *not* override a source file absolute path but
    # *should* affect the destination file path.
    context "when created with an absolute path and root" do
      before do
        @name                  = 'content.html'
        @root                  = '/tmp/mint-test/alternative-root'
        @root_directory        = '/tmp/mint-test/alternative-root'
        @source                = '/tmp/mint-test/content.md'
        @source_file           = '/tmp/mint-test/content.md'
        @source_directory      = '/tmp/mint-test'
        @destinaton            = nil
        @destination_file      = '/tmp/mint-test/alternative-root/content.html'
        @destination_directory = '/tmp/mint-test/alternative-root'
      end

      let(:resource) { Resource.new '/tmp/mint-test/content.md',
                       :root => '/tmp/mint-test/alternative-root' }

      it_behaves_like "all resources"
    end

    context "when it's created with a block" do
      before do
        @name                  = 'content.html'
        @root                  = '/tmp/mint-test/alternative-root'
        @root_directory        = '/tmp/mint-test/alternative-root'
        @source                = 'content.md'
        @source_file           = '/tmp/mint-test/alternative-root/content.md'
        @source_directory      = '/tmp/mint-test/alternative-root'
        @destination            = 'destination'
        @destination_file      = '/tmp/mint-test/alternative-root/destination/content.html'
        @destination_directory = '/tmp/mint-test/alternative-root/destination'
      end

      let(:resource) do
        Resource.new @content_file do |resource|
          resource.root = '/tmp/mint-test/alternative-root'
          resource.destination = 'destination'
        end
      end

      it_behaves_like "all resources"
    end
  end
end
