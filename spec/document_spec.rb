require "spec_helper"

module Mint
  describe Document do
    describe "#transform_markdown_links" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          File.write("test.md", "# Test Document")
          File.write("layout.erb", "<%= content %>")
          File.write("style.css", "body { font-family: sans-serif; }")
          example.run
        end
      end

      let(:document) do
        Document.new(
          working_directory: Pathname.new(@test_dir),
          source_path: Pathname.new("test.md"),
          destination_path: Pathname.new("test.html"),
          destination_directory_path: Pathname.new("output"),
          layout_path: Pathname.new("layout.erb"),
          style_path: Pathname.new("style.css"),
          style_destination_path: Pathname.new("output"),
          style_mode: :inline,
          transform_links: proc {|basename| "#{basename}.html" },
          options: { insert_title_heading: false }
        )
      end

      it "transforms .md links to .html links" do
        text = "Check out [this document](other.md) for more info."
        result = document.transform_markdown_links(text) {|basename| "#{basename}.html" }
        expect(result).to eq("Check out [this document](other.html) for more info.")
      end

      it "preserves absolute URLs unchanged" do
        text = "Visit [our website](https://example.com/page.md) for details."
        result = document.transform_markdown_links(text) {|basename| "#{basename}.html" }
        expect(result).to eq("Visit [our website](https://example.com/page.md) for details.")
      end

      it "respects custom output file format via block" do
        text = "See [document](file.md) here."
        result = document.transform_markdown_links(text) {|basename| "#{basename}_converted.html" }
        expect(result).to eq("See [document](file_converted.html) here.")
      end

      it "handles multiple links in same text" do
        text = "Read [doc1](first.md) and [doc2](second.md)."
        result = document.transform_markdown_links(text) {|basename| "#{basename}.html" }
        expect(result).to eq("Read [doc1](first.html) and [doc2](second.html).")
      end
    end
  end
end