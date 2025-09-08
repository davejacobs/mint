require "spec_helper"

module Mint
  describe Document do
    describe ".transform_markdown_links" do
      it "transforms .md links to .html links" do
        text = "Check out [this document](other.md) for more info."
        result = Document.transform_markdown_links(text)
        expect(result).to eq("Check out [this document](other.html) for more info.")
      end

      it "preserves absolute URLs unchanged" do
        text = "Visit [our website](https://example.com/page.md) for details."
        result = Document.transform_markdown_links(text)
        expect(result).to eq("Visit [our website](https://example.com/page.md) for details.")
      end

      it "respects custom output file format" do
        text = "See [document](file.md) here."
        result = Document.transform_markdown_links(text, 
          output_file_format: "%{name}_converted.%{ext}")
        expect(result).to eq("See [document](file_converted.html) here.")
      end

      it "handles multiple links in same text" do
        text = "Read [doc1](first.md) and [doc2](second.md)."
        result = Document.transform_markdown_links(text)
        expect(result).to eq("Read [doc1](first.html) and [doc2](second.html).")
      end
    end
  end
end