require "spec_helper"

module Mint
  describe Helpers do
    describe ".underscore" do
      it "underscores class names per ActiveSupport conventions" do
        expect(Helpers.underscore("ClassName")).to eq("class_name")
      end

      it "allows for camel case prefixes" do
        expect(Helpers.underscore("EPub")).to eq("e_pub")
        expect(Helpers.underscore("EPub", :ignore_prefix => true)).to eq("epub")
      end

      it "allows for namespace removal" do
        expect(Helpers.underscore("Mint::EPub", 
                           :namespaces => true)).to eq("mint/e_pub")
        expect(Helpers.underscore("Mint::EPub", 
                           :namespaces => false)).to eq("e_pub")
        expect(Helpers.underscore("Mint::EPub", 
                           :namespaces => true, 
                           :ignore_prefix => true)).to eq("mint/epub")
      end
    end
    
    describe ".slugize" do
      it "downcases everything" do
        expect(Helpers.slugize("This could use FEWER CAPITALS")).to eq(
          "this-could-use-fewer-capitals")
      end

      it "parses 'and'" do
        expect(Helpers.slugize("You & me")).to eq("you-and-me")
      end

      it "parses spaces" do
        expect(Helpers.slugize("You     and me")).to eq("you-and-me")
      end

      it "removes non-word/non-digits" do
        expect(Helpers.slugize("You // and :: me")).to eq("you-and-me")
      end

      it "condenses multiple hyphens" do
        expect(Helpers.slugize("You-----and me")).to eq("you-and-me")
      end
    end

    describe ".symbolize" do
      it "converts hyphens to underscores" do
        expect(Helpers.symbolize("you-and-me")).to eq(:you_and_me)
      end
    end

    describe ".pathize" do
      it "converts a String to a Pathname" do
        expect(Helpers.pathize("filename.md")).to eq(
          Pathname.new("filename.md").expand_path)
      end

      it "does not convert a Pathname" do
        pathname = Pathname.new("filename.md")
        expect(Helpers.pathize(pathname)).to eq(pathname.expand_path)
      end
    end

    describe ".symbolize_keys" do
      it "turns all string keys in a flat map into symbols" do
        flat_map = {
          "key1" => "value1",
          "key2" => "value2",
          "key3" => "value3"
        }

        expected_map = {
          key1: "value1",
          key2: "value2",
          key3: "value3"
        }

        expect(Helpers.symbolize_keys(flat_map)).to eq(expected_map)
      end

      it "recursively turns all string keys in a nested map into symbols" do
        nested_map = {
          "key1" => "value1",
          "key2" => "value2",
          "key3" => "value3",
          "key4" => {
            "nested_key1" => "nested_value1",
            "nested_key2" => "nested_value2"
          }
        }

        expected_map = {
          key1: "value1",
          key2: "value2",
          key3: "value3",
          key4: {
            nested_key1: "nested_value1",
            nested_key2: "nested_value2"
          }
        }

        expect(Helpers.symbolize_keys(nested_map)).to eq(expected_map)
      end

      it "recursively downcases all keys if specified" do
        capitalized_map = {
          "Key1" => "value1",
          "Key2" => "value2",
          "Key3" => "value3",
          "Key4" => {
            "Nested_key1" => "nested_value1",
            "Nested_key2" => "nested_value2"
          }
        }

        expected_map = {
          key1: "value1",
          key2: "value2",
          key3: "value3",
          key4: {
            nested_key1: "nested_value1",
            nested_key2: "nested_value2"
          }
        }

        expect(Helpers.symbolize_keys(capitalized_map, :downcase => true)).to eq(expected_map)
      end
    end

    describe ".listify" do
      it "joins a list of three or more with an ampersand, without the Oxford comma" do
        expect(Helpers.listify(["Alex", "Chris", "John"])).to eq(
          "Alex, Chris & John")
      end

      it "joins a list of two with an ampersand" do
        expect(Helpers.listify(["Alex", "Chris"])).to eq("Alex & Chris")
      end

      it "does not do anything to a list of one" do
        expect(Helpers.listify(["Alex"])).to eq("Alex")
      end
    end

    describe ".standardize" do
      before do
        @nonstandard = {
          title: "Title",
          author: "David",
          editors: ["David", "Jake"],
          barcode: "Unique ID"
        }

        @table = {
          author: [:creators, :array],
          editors: [:collaborators, :array],
          barcode: [:uuid, :string]
        }

        @standard = {
          title: "Title",
          creators: ["David"],
          collaborators: ["David", "Jake"],
          uuid: "Unique ID"
        }
      end

      it "converts all nonstandard keys to standard ones" do
        expect(Helpers.standardize(@nonstandard, 
                            :table => @table)).to eq(@standard)
      end
    end

    describe ".hashify" do
      it "zips two lists of the same size into a Hash" do
        expect(Helpers.hashify([:one, :two, :three], [1, 2, 3])).to eq({
          one: 1,
          two: 2,
          three: 3
        })
      end
    end

    describe ".normalize_path" do
      it "handles two files in the same directory" do
        path1 = "~/file1"
        path2 = "~/file2"
        expect(Helpers.normalize_path(path1, path2)).to eq(
          Pathname.new("../file1"))
      end
      
      it "handles two files one directory apart" do
        path1 = "~/file1"
        path2 = "~/subdir/file2"
        expect(Helpers.normalize_path(path1, path2)).to eq(
          Pathname.new("../../file1"))
      end

      it "handles two files linked only at the directory root" do
        path1 = "/home/david/file1"
        path2 = "/usr/local/src/file2"
        expect(Helpers.normalize_path(path1, path2)).to eq(
          Pathname.new("/home/david/file1"))
      end
      
      it "returns nil for identical files" do
        path1 = "~/file1"
        path2 = "~/file1"
        expect(Helpers.normalize_path(path1, path2)).to eq(Pathname.new("."))
      end
    end

    describe ".update_yaml!" do
      before do
        File.open "example.yaml", "w" do |file|
          file << "conflicting: foo\nnon-conflicting: bar"
        end
      end

      it "combines specified data with data in YAML file and updates file" do
        Helpers.update_yaml! "example.yaml", "conflicting" => "baz"
        expect(YAML.load_file("example.yaml")["conflicting"]).to eq("baz")
      end
    end

    describe ".generate_temp_file!" do
      before do
        @file = Helpers.generate_temp_file! "content.md"
        @path = Pathname.new @file
      end

      it "creates a randomly named temp file" do
        expect(@path).to exist
      end

      it "creates a temp file with the correct name and extension" do
        expect(@path.basename.to_s).to match(/content/)
        expect(@path.extname).to eq(".md")
      end

      it "fills the temp file with the specified content" do
        expect(@path.read).to match(/This is just a test/)
      end
    end
  end
end
