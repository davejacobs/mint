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
    before do
      @source_file = @content_file

      # Hack because we can't reach into suite scope
      @tmp_dir = Dir.getwd 
    end

    context "when created with a relative path, no root" do
      let(:resource) { Resource.new @source_file }

      it "#name" do
        resource.name.should =~ /#{@source_file.gsub /\.\w*/, ''}/ 
      end

      it "#root_directory_path" do
        resource.root_directory_path.should == Pathname.new(@tmp_dir)
      end

      it "#root_directory" do
        resource.root_directory.should == resource.root_directory_path.to_s
      end

      it "#source" do
        resource.source.should == @source_file
      end

      it "#source_file_path" do
        path = Pathname.new(resource.source)
        if path.absolute?
          resource.source_file_path.should == path
        else
          resource.source_file_path.should == 
            resource.root_directory_path + path
        end
      end

      # May have to call expand_path for all these dirnames
      it "#source_directory_path" do
        resource.source_directory_path.should == 
          resource.source_file_path.dirname
      end

      it "#source_file" do
        resource.source_file.should == 
          resource.source_file_path.to_s
      end

      it "#source_directory" do
        resource.source_directory.should == 
          resource.source_directory_path.to_s
      end

      it "#destination" do
        resource.destination.should == ''
      end

      it "#destination_file_path" do
        resource.destination_file_path.should ==
          resource.root_directory_path + resource.destination + resource.name
      end
      
      it "#destination_directory_path" do
        resource.destination_directory_path.should == 
          resource.destination_file_path.dirname
      end

      it "#destination_file" do
        resource.destination_file.should == 
          resource.destination_file_path.to_s
      end

      it "#destination_directory" do
        resource.destination_directory.should == 
          resource.destination_directory_path.to_s
      end

      it "#equal?" do
        resource.should equal(Resource.new(@source_file))
      end
    end

    context "when created with a relative path and absolute root" do
      let(:resource) do
        # @alternative_root is defined in spec_helper
        Resource.new @source_file, :root => @alternative_root
      end
    end

    context "when created with an absolute path, no root" do
      let(:resource) do
        Resource.new "#{@tmp_dir}/#{@source_file}" 
      end
    end

    # Probably should not happen
    context "when created with an absolute path and root" do
      let(:resource) do
        Resource.new "#{@tmp_dir}/#{@source_file}", :root => @alternative_root
      end
    end
  end
end
