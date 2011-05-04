require 'spec_helper'

module Mint
  describe Resource do
    before do 
      @tmp_dir = Dir.getwd 
      @alternative_root = "#{@tmp_dir}/alternative-root"
    end

    shared_examples_for "all resources" do
      subject { resource }

      its(:root_directory_path) { should be_path(resource.root_directory) }
      its(:source_file_path) { should be_path(resource.source_file) }
      its(:source_directory_path) { should be_path(resource.source_directory) }
      its(:destination_file_path) { should be_path(resource.destination_file) }
      its(:destination_directory_path) do
        should be_path(resource.destination_directory)
      end
    end

    context "when created with a relative path and no root" do
      let(:resource) { Resource.new @content_file }
      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == @tmp_dir }
      its(:source) { should == @content_file }
      its(:source_file) { should == "#{@tmp_dir}/#{@content_file}" }
      its(:source_directory) { should == @tmp_dir }
      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@tmp_dir}/content.html" }
      its(:destination_directory) { should == @tmp_dir }

      it_should_behave_like "all resources"
    end

    context "when created with a relative path and absolute root" do
      let(:resource) { Resource.new @content_file, :root => @alternative_root }
      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == @alternative_root }
      its(:source) { should == @content_file }
      its(:source_file) { should == "#{@alternative_root}/#{@content_file}" }
      its(:source_directory) { should == @alternative_root }
      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@alternative_root}/content.html" }
      its(:destination_directory) { should == @alternative_root }

      it_should_behave_like "all resources"
    end

    context "when created with an absolute path, no root" do
      before do
        # This is a use case we will only ever test here, so
        # I'm not going to include it in the spec_helper
        FileUtils.mkdir_p @alternative_root
        File.open("#{@alternative_root}/#{@content_file}", 'w') do |f|
          f << @content
        end
      end

      let(:resource) { Resource.new "#{@alternative_root}/#{@content_file}" }
      subject { resource }
      
      its(:name) { should == 'content.html' }
      its(:root) { should == @alternative_root }
      its(:source) { should == "#{@alternative_root}/#{@content_file}" }
      its(:source_file) { should == "#{@alternative_root}/#{@content_file}" }
      its(:source_directory) { should == @alternative_root }
      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@alternative_root}/content.html" }
      its(:destination_directory) { should == @alternative_root }

      it_should_behave_like "all resources"
    end

    # The root should *not* override a source file absolute path but
    # *should* affect the destination file path.
    # I should also test this when neither the source nor the root
    # are in Dir.getwd, which is the default root.
    context "when created with an absolute path and root" do
      let(:resource) { Resource.new "#{@tmp_dir}/#{@content_file}",
                       :root => @alternative_root }

      subject { resource }

      its(:name) { should == 'content.html' }
      its(:root) { should == @alternative_root }
      its(:source) { should == "#{@tmp_dir}/#{@content_file}" }
      its(:source_file) { should =="#{@tmp_dir}/#{@content_file}" }
      its(:source_directory) { should == @tmp_dir }
      its(:destination) { should be_nil }
      its(:destination_file) { should == "#{@alternative_root}/content.html" }
      its(:destination_directory) { should == @alternative_root }

      it_should_behave_like "all resources"
    end

    context "when it's created with a block" do
      let(:resource) do
        Resource.new @content_file do |resource|
          resource.root = @alternative_root
          resource.destination = 'destination'
        end
      end

      subject { resource }
      
      its(:name) { should == 'content.html' }
      its(:root) { should == @alternative_root }
      its(:source) { should == @content_file }
      its(:source_file) { should == "#{@alternative_root}/#{@content_file}" }
      its(:source_directory) { should == @alternative_root }
      its(:destination) { should == 'destination' }

      its(:destination_file) do
        should == "#{@alternative_root}/destination/content.html"
      end

      its(:destination_directory) do
        should == "#{@alternative_root}/destination"
      end

      it_should_behave_like "all resources"
    end
  end
end
