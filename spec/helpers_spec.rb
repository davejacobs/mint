require 'spec_helper'

module Mint
  describe Helpers do
    describe ".underscore" do
      it "underscores class names per ActiveSupport conventions" do
        Helpers.underscore('ClassName').should == 'class_name'
      end

      it "allows for camel case prefixes" do
        Helpers.underscore('EPub').should == 'e_pub'
        Helpers.underscore('EPub', :ignore_prefix => true).should == 'epub'
      end

      it "allows for namespace removal" do
        Helpers.underscore('Mint::EPub', 
                           :namespaces => true).should == 'mint/e_pub'
        Helpers.underscore('Mint::EPub', 
                           :namespaces => false).should == 'e_pub'
        Helpers.underscore('Mint::EPub', 
                           :namespaces => true, 
                           :ignore_prefix => true).should == 'mint/epub'
      end
    end
    
    describe ".slugize" do
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

    describe ".symbolize" do
      it "converts hyphens to underscores" do
        Helpers.symbolize('you-and-me').should == :you_and_me
      end
    end

    describe ".pathize" do
      it "converts a String to a Pathname" do
        Helpers.pathize("filename.md").should == 
          Pathname.new("filename.md").expand_path
      end

      it "does not convert a Pathname" do
        pathname = Pathname.new("filename.md")
        Helpers.pathize(pathname).should == pathname.expand_path
      end
    end

    describe ".symbolize_keys" do
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

      it "recursively downcases all keys if specified" do
        capitalized_map = {
          'Key1' => 'value1',
          'Key2' => 'value2',
          'Key3' => 'value3',
          'Key4' => {
            'Nested_key1' => 'nested_value1',
            'Nested_key2' => 'nested_value2'
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

        Helpers.symbolize_keys(capitalized_map, :downcase => true).should == expected_map
      end
    end

    describe ".listify" do
      it "joins a list of three or more with an ampersand, without the Oxford comma" do
        Helpers.listify(['Alex', 'Chris', 'John']).should ==
          'Alex, Chris & John'
      end

      it "joins a list of two with an ampersand" do
        Helpers.listify(['Alex', 'Chris']).should == 'Alex & Chris'
      end

      it "does not do anything to a list of one" do
        Helpers.listify(['Alex']).should == 'Alex'
      end
    end

    describe ".standardize" do
      before do
        @nonstandard = {
          title: 'Title',
          author: 'David',
          editors: ['David', 'Jake'],
          barcode: 'Unique ID'
        }

        @table = {
          author: [:creators, :array],
          editors: [:collaborators, :array],
          barcode: [:uuid, :string]
        }

        @standard = {
          title: 'Title',
          creators: ['David'],
          collaborators: ['David', 'Jake'],
          uuid: 'Unique ID'
        }
      end

      it "converts all nonstandard keys to standard ones" do
        Helpers.standardize(@nonstandard, 
                            :table => @table).should == @standard
      end
    end

    describe ".hashify" do
      it "zips two lists of the same size into a Hash" do
        Helpers.hashify([:one, :two, :three], [1, 2, 3]).should == {
          one: 1,
          two: 2,
          three: 3
        }
      end
    end

    describe ".normalize_path" do
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

    describe ".update_yaml!" do
      it "loads existing YAML data from file"
      it "combines existing YAML data with new data and writes to file"
    end

    describe ".generate_temp_file!" do
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
