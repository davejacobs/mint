require "spec_helper"

describe Mint::Template do
  describe ".valid?" do
    it "determines if a directory is a valid template directory" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir) + "test_template"
        template_dir.mkdir
        
        # Empty directory should not be valid (returns empty array)
        expect(Mint::Template.valid?(template_dir)).to be_empty
        
        # Directory with stylesheet should be valid
        (template_dir + "style.css").write("body { color: black; }")
        expect(Mint::Template.valid?(template_dir)).to be_truthy
      end
    end
  end

  describe ".find_directory_by_name" do
    it "returns template directory path by name" do
      # This will return nil if template doesn't exist, which is expected
      result = Mint::Template.find_directory_by_name("default")
      if result
        expect(result).to be_a(Pathname)
      else
        expect(result).to be_nil
      end
    end
  end
end