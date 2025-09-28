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
          autodrop_prefix_path: Pathname.new("."),
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

    describe "#parse_metadata_from" do
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
          autodrop_prefix_path: Pathname.new("."),
          source_path: Pathname.new("test.md"),
          destination_path: Pathname.new("test.html"),
          destination_directory_path: Pathname.new("output"),
          layout_path: Pathname.new("layout.erb"),
          style_path: Pathname.new("style.css"),
          style_destination_path: Pathname.new("output"),
          style_mode: :inline,
          transform_links: proc {|basename| basename }
        )
      end

      context "with valid YAML front matter" do
        let(:content) do
          <<~MARKDOWN
            ---
            title: My Test Document
            author: John Doe
            Date Created: "2024-01-01"
            Some Key With Spaces: value with spaces
            ---

            # This is my markdown content

            Here is some regular markdown text.
          MARKDOWN
        end

        it "parses metadata and content correctly" do
          metadata, body = document.send(:parse_metadata_from, content)

          expect(metadata).to eq({
            title: "My Test Document",
            author: "John Doe",
            date_created: "2024-01-01",
            some_key_with_spaces: "value with spaces"
          })

          expect(body.strip).to eq("# This is my markdown content\n\nHere is some regular markdown text.")
        end

        it "converts keys to symbols" do
          metadata, _ = document.send(:parse_metadata_from, content)

          expect(metadata.keys).to all(be_a(Symbol))
        end

        it "downcases keys" do
          metadata, _ = document.send(:parse_metadata_from, content)

          expect(metadata).to have_key(:date_created)
          expect(metadata).not_to have_key(:Date_Created)
        end

        it "converts spaces to underscores in keys" do
          metadata, _ = document.send(:parse_metadata_from, content)

          expect(metadata).to have_key(:some_key_with_spaces)
          expect(metadata).not_to have_key(:"Some Key With Spaces")
        end
      end

      context "with no front matter" do
        let(:content) do
          <<~MARKDOWN
            # This is my markdown content

            Here is some regular markdown text with no front matter.
          MARKDOWN
        end

        it "returns empty metadata and full content" do
          metadata, body = document.send(:parse_metadata_from, content)

          expect(metadata).to eq({})
          expect(body).to eq(content)
        end
      end

      context "with invalid YAML front matter" do
        let(:content) do
          <<~MARKDOWN
            ---
            title: My Test Document
            invalid: yaml: content: here
            ---

            # This is my markdown content
          MARKDOWN
        end

        it "raises friendly error on YAML syntax error" do
          expect {
            document.send(:parse_metadata_from, content)
          }.to raise_error(/Invalid YAML in front matter/)
        end
      end

      context "with incomplete front matter" do
        let(:content) do
          <<~MARKDOWN
            ---
            title: My Test Document
            author: John Doe

            # This content has no closing delimiter
          MARKDOWN
        end

        it "returns empty metadata when missing closing delimiter" do
          metadata, body = document.send(:parse_metadata_from, content)

          expect(metadata).to eq({})
          expect(body).to eq(content)
        end
      end
    end
  end
end