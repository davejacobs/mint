require "spec_helper"

describe "Original style mode integration" do
  context "in isolated environment" do
    around(:each) do |example|
      in_temp_dir do |dir|
        @test_dir = dir
        create_template_directory("default")
        example.run
      end
    end

    describe "with --style-mode original" do
      it "works with built-in templates in original mode" do
        create_markdown_path("test.md", "# Test Document\n\nThis is a test.")

        # Create output directory structure
        Dir.chdir(@test_dir) do
          config = Mint::Config.with_defaults(
            style_mode: :original,
            layout_name: "default",
            style_name: "default"
          )

          expect {
            Mint::Commandline.publish!([Pathname.new("test.md")], config: config)
          }.not_to raise_error

          expect(File.exist?("test.html")).to be true

          content = File.read("test.html")
          expect(content).to include("<h1>Test Document</h1>")
          expect(content).to include("<p>This is a test.</p>")
        end
      end

      it "correctly outputs original style mode with different templates" do
        create_markdown_path("test.md", "# Nord Test\n\nTesting with Nord theme.")
        create_template_directory("nord")

        Dir.chdir(@test_dir) do
          config = Mint::Config.with_defaults(
            style_mode: :original,
            layout_name: "nord",
            style_name: "nord"
          )

          # Should work with any template that exists, or fall back gracefully
          expect {
            Mint::Commandline.publish!([Pathname.new("test.md")], config: config)
          }.not_to raise_error

          expect(File.exist?("test.html")).to be true
        end
      end
    end
  end
end