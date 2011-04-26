require 'spec_helper'

module Mint
  describe Resource do
    context "when created with a relative path and no root" do
      let(:resource) { Resource.new @content_file }

      subject { resource }
      its(:name) { should == 'content.html' }
      its(:root) { should be_nil }
      its(:root_directory_path) { should == Pathname.new(resource.root_directory) }
      its(:source) { should == 'content.md' }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:source_file_path) { should == Pathname.new(resource.source_file) }
      its(:source_directory_path) { should == Pathname.new(resource.source_directory) }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test' }
      its(:destination_file_path) { should == Pathname.new(resource.destination_file) }
      its(:destination_directory_path) { should == Pathname.new(resource.destination_directory) }
    end

    context "when created with a relative path and absolute root" do
      let(:resource) { Resource.new @content_file,
                       :root => '/tmp/mint-test/alternative-root' }

      subject { resource }
      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test/alternative-root' }
      its(:root_directory_path) { should == Pathname.new(resource.root_directory) }
      its(:source) { should == 'content.md' }
      its(:source_file_path) { should == Pathname.new('/tmp/mint-test/alternative-root/content.md') }
      its(:source_file) { should == '/tmp/mint-test/alternative-root/content.md' }
      its(:source_directory_path) { should == Pathname.new('/tmp/mint-test/alternative-root') }
      its(:source_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/alternative-root/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination_file_path) { should == Pathname.new(resource.destination_file) }
      its(:destination_directory_path) { should == Pathname.new(resource.destination_directory) }
    end

    context "when created with a relative path and absolute root" do
      let(:resource) { Resource.new "/tmp/mint-test/#{@content_file}" }

      subject { resource }
      its(:name) { should == 'content.html' }
      its(:root) { should be_nil }
      its(:root_directory_path) { should == Pathname.new(resource.root_directory) }
      its(:source) { should == '/tmp/mint-test/content.md' }
      its(:source_file_path) { should == Pathname.new('/tmp/mint-test/content.md') }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory_path) { should == Pathname.new('/tmp/mint-test') }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test' }
      its(:destination_file_path) { should == Pathname.new(resource.destination_file) }
      its(:destination_directory_path) { should == Pathname.new(resource.destination_directory) }
    end

    # The root should *not* override a source file absolute path but
    # *should* affect the destination file path.
    context "when created with an absolute path and root" do
      let(:resource) { Resource.new '/tmp/mint-test/content.md',
                       :root => '/tmp/mint-test/alternative-root' }

      subject { resource }
      its(:name) { should == 'content.html' }
      its(:root) { should == '/tmp/mint-test/alternative-root' }
      its(:root_directory_path) { should == Pathname.new(resource.root_directory) }
      its(:source) { should == '/tmp/mint-test/content.md' }
      its(:source_file_path) { should == Pathname.new('/tmp/mint-test/content.md') }
      its(:source_file) { should == '/tmp/mint-test/content.md' }
      its(:source_directory_path) { should == Pathname.new('/tmp/mint-test') }
      its(:source_directory) { should == '/tmp/mint-test' }
      its(:destination) { should be_nil }
      its(:destination_file) { should == '/tmp/mint-test/alternative-root/content.html' }
      its(:destination_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination_file_path) { should == Pathname.new(resource.destination_file) }
      its(:destination_directory_path) { should == Pathname.new(resource.destination_directory) }
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
      its(:root_directory_path) { should == Pathname.new(resource.root_directory) }
      its(:source) { should == 'content.md' }
      its(:source_file_path) { should == Pathname.new('/tmp/mint-test/alternative-root/content.md') }
      its(:source_file) { should == '/tmp/mint-test/alternative-root/content.md' }
      its(:source_directory_path) { should == Pathname.new('/tmp/mint-test/alternative-root') }
      its(:source_directory) { should == '/tmp/mint-test/alternative-root' }
      its(:destination) { should == 'destination' }
      its(:destination_file_path) { should == Pathname.new('/tmp/mint-test/alternative-root/destination/content.html') }
      its(:destination_file) { should == '/tmp/mint-test/alternative-root/destination/content.html' }
      its(:destination_directory_path) { should == Pathname.new('/tmp/mint-test/alternative-root/destination') }
      its(:destination_directory) { should == '/tmp/mint-test/alternative-root/destination' }
    end
  end
end
