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

      it "parses multiple hyphens" do
        Helpers.slugize('You-----and me').should == 'you-and-me'
      end

      it "removes non-word/non-digits" do
        Helpers.slugize('You // and :: me').should == 'you-and-me'
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
  end
end
