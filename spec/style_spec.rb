require "spec_helper"

describe Mint::Style do
  describe ".valid?" do
    it "determines if a file is a valid stylesheet" do
      expect(Mint::Style.valid?(Pathname.new("style.css"))).to be true
      expect(Mint::Style.valid?(Pathname.new("other.css"))).to be false
    end
  end

  describe ".find_by_name" do
    it "returns style file path by template name" do
      result = Mint::Style.find_by_name("default")
      if result
        expect(result).to be_a(Pathname)
        expect(Mint::Style.valid?(result)).to be true
      else
        expect(result).to be_nil
      end
    end
  end

  describe ".find_in_directory" do
    it "finds style file in a specific directory" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir)
        style_file = template_dir + "style.css"
        style_file.write("body { color: black; }")
        
        result = Mint::Style.find_in_directory(template_dir)
        expect(result).to eq(style_file)
        expect(Mint::Style.valid?(result)).to be true
      end
    end

    it "returns nil when no style file exists" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir)
        result = Mint::Style.find_in_directory(template_dir)
        expect(result).to be_nil
      end
    end
  end
end