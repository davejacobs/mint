require "spec_helper"

module Mint
  describe Helpers do
    describe ".normalize_path" do
      it "handles two files in the same directory" do
        from_dir = Pathname.new("/home/user/project")
        to_dir = Pathname.new("/home/user/project/file.txt")
        result = Helpers.normalize_path(to_dir, from_dir)
        expect(result.to_s).to eq("file.txt")
      end

      it "handles two files one directory apart" do
        from_dir = Pathname.new("/home/user/project")
        to_dir = Pathname.new("/home/user/project/subdir")
        result = Helpers.normalize_path(to_dir, from_dir)
        expect(result.to_s).to eq("subdir")
      end

      it "handles two files linked only at the directory root" do
        from_dir = Pathname.new("/home/user/project")
        to_dir = Pathname.new("/home/other/file.txt")
        result = Helpers.normalize_path(to_dir, from_dir)
        # Returns a relative path when directories share a common root
        expect(result.to_s).to eq("../../other/file.txt")
      end
    end

    describe ".transform_markdown_links" do
      it "transforms .md links to .html links" do
        text = "Check out [this document](other.md) for more info."
        result = Helpers.transform_markdown_links(text)
        expect(result).to eq("Check out [this document](other.html) for more info.")
      end

      it "preserves absolute URLs unchanged" do
        text = "Visit [our website](https://example.com/page.md) for details."
        result = Helpers.transform_markdown_links(text)
        expect(result).to eq("Visit [our website](https://example.com/page.md) for details.")
      end

      it "respects custom output file format" do
        text = "See [document](file.md) here."
        result = Helpers.transform_markdown_links(text, 
          output_file_format: "%{basename}_converted.%{new_extension}")
        expect(result).to eq("See [document](file_converted.html) here.")
      end

      it "handles multiple links in same text" do
        text = "Read [doc1](first.md) and [doc2](second.md)."
        result = Helpers.transform_markdown_links(text)
        expect(result).to eq("Read [doc1](first.html) and [doc2](second.html).")
      end
    end

    describe ".format_output_file" do
      it "formats basic filename with new extension" do
        result = Helpers.format_output_file("document.md")
        expect(result).to eq("document.html")
      end

      it "uses custom format string" do
        result = Helpers.format_output_file("document.md", 
          format_string: "%{basename}_output.%{new_extension}")
        expect(result).to eq("document_output.html")
      end

      it "provides access to original extension" do
        result = Helpers.format_output_file("document.md", 
          format_string: "%{basename}.%{original_extension}.%{new_extension}")
        expect(result).to eq("document.md.html")
      end

      it "handles files without extension" do
        result = Helpers.format_output_file("README")
        expect(result).to eq("README.html")
      end
    end
  end
end