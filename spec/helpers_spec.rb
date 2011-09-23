require 'spec_helper'

module Mint
  describe Helpers do
    describe "#slugize" do
      it "downcases everything" do
        Helpers.slugize('This could use FEWER CAPITALS').should ==
          'this-could-use-fewer-capitals'
      end

      it "parses 'and'" do
        Helpers.slugize('You & me').should == 'you-and-me'
      end

      it "parses spaces" do
        Helpers.slugize('You     and me').should == 'you-and-me'
      end

      it "removes non-word/non-digits" do
        Helpers.slugize('You // and :: me').should == 'you-and-me'
      end

      it "condenses multiple hyphens" do
        Helpers.slugize('You-----and me').should == 'you-and-me'
      end
    end

    describe "#symbolize" do
      it "converts hyphens to underscores" do
        Helpers.symbolize('you-and-me').should == :you_and_me
      end
    end

    describe "#pathize" do
      it "converts a String to a Pathname" do
        Helpers.pathize("filename.md").should == 
          Pathname.new("filename.md").expand_path
      end

      it "does not convert a Pathname" do
        pathname = Pathname.new("filename.md")
        Helpers.pathize(pathname).should == pathname.expand_path
      end
    end

    describe "#symbolize_keys" do
      it "turns all string keys in a flat map into symbols" do
        flat_map = {
          'key1' => 'value1',
          'key2' => 'value2',
          'key3' => 'value3'
        }

        expected_map = {
          key1: 'value1',
          key2: 'value2',
          key3: 'value3'
        }

        Helpers.symbolize_keys(flat_map).should == expected_map
      end

      it "recursively turns all string keys in a nested map into symbols" do
        nested_map = {
          'key1' => 'value1',
          'key2' => 'value2',
          'key3' => 'value3',
          'key4' => {
            'nested_key1' => 'nested_value1',
            'nested_key2' => 'nested_value2'
          }
        }

        expected_map = {
          key1: 'value1',
          key2: 'value2',
          key3: 'value3',
          key4: {
            nested_key1: 'nested_value1',
            nested_key2: 'nested_value2'
          }
        }

        Helpers.symbolize_keys(nested_map).should == expected_map
      end
    end

    describe "#normalize_path" do
      it "handles two files in the same directory" do
        path1 = '~/file1'
        path2 = '~/file2'
        Helpers.normalize_path(path1, path2).should == 
          Pathname.new('../file1')
      end
      
      it "handles two files one directory apart" do
        path1 = '~/file1'
        path2 = '~/subdir/file2'
        Helpers.normalize_path(path1, path2).should == 
          Pathname.new('../../file1')
      end

      it "handles two files linked only at the directory root" do
        path1 = '/home/david/file1'
        path2 = '/usr/local/src/file2'
        Helpers.normalize_path(path1, path2).should == 
          Pathname.new('/home/david/file1')
      end
      
      it "returns nil for identical files" do
        path1 = '~/file1'
        path2 = '~/file1'
        Helpers.normalize_path(path1, path2).should == Pathname.new('.')
      end
    end

    describe "#update_yaml" do
      it "loads existing YAML data from file"
      it "combines existing YAML data with new data and writes to file"
    end

    describe "#generate_temp_file!" do
      before do
        @file = Helpers.generate_temp_file! 'content.md'
        @path = Pathname.new @file
      end

      it "creates a randomly named temp file" do
        @path.should exist
      end

      it "creates a temp file with the correct name and extension" do
        @path.basename.to_s.should =~ /content/
        @path.extname.should == '.md'
      end

      it "fills the temp file with the specified content" do
        @path.read.should =~ /This is just a test/
      end
    end
  end
end
