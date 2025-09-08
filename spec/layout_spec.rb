require "spec_helper"

describe Mint::Layout do
  describe ".valid?" do
    it "determines if a file is a valid layout file" do
      expect(Mint::Layout.valid?(Pathname.new("layout.html"))).to be true
      expect(Mint::Layout.valid?(Pathname.new("layout.erb"))).to be true
      expect(Mint::Layout.valid?(Pathname.new("other.html"))).to be false
    end
  end

  describe ".find_by_name" do
    it "returns layout file path by template name" do
      result = Mint::Layout.find_by_name("default")
      if result
        expect(result).to be_a(Pathname)
        expect(Mint::Layout.valid?(result)).to be true
      else
        expect(result).to be_nil
      end
    end
  end

  describe ".find_in_directory" do
    it "finds layout file in a specific directory" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir)
        layout_file = template_dir + "layout.html"
        layout_file.write("<html><%= content %></html>")
        
        result = Mint::Layout.find_in_directory(template_dir)
        expect(result).to eq(layout_file)
        expect(Mint::Layout.valid?(result)).to be true
      end
    end

    it "returns nil when no layout file exists" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir)
        result = Mint::Layout.find_in_directory(template_dir)
        expect(result).to be_nil
      end
    end
  end
end