require "spec_helper"

RSpec.describe "Full CLI Workflow Integration" do
  describe "complete user workflows" do
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          example.run
        end
      end

      describe "new user getting started" do
        it "can set up a new project from scratch" do
          # 1. Create configuration file manually (since set command was removed)
          FileUtils.mkdir_p(".mint")
          File.write(".mint/config.toml", <<~TOML)
            layout = "default"
            style = "default"
            destination = "output"
          TOML

          # 2. Create content files
          create_markdown_file("index.md", <<~MARKDOWN)
            # Welcome to My Site
            
            This is my new project built with Mint.
            
            ## Features
            - Simple Markdown processing
            - Clean HTML output
            - Customizable templates
          MARKDOWN

          create_markdown_file("about.md", "# About\n\nThis is the about page.")

          # 3. Create output directory and publish
          FileUtils.mkdir_p("output")
          config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"))
          
          expect {
            Mint::Commandline.publish!(["index.md", "about.md"], config: config)
          }.not_to raise_error

          # 4. Verify output
          expect(File.exist?("output/index.html")).to be true
          expect(File.exist?("output/about.html")).to be true

          # Check content
          index_content = File.read("output/index.html")
          expect(index_content).to include("<h1>Welcome to My Site</h1>")
          expect(index_content).to include("<h2>Features</h2>")
        end
      end

      describe "documentation site workflow" do
        it "can build a multi-page documentation site" do
          # Set up configuration for documentation
          config = Mint::Config.with_defaults(
            layout_name: "default",
            style_name: "default",
            destination_directory: Pathname.new("docs"),
            preserve_structure: true  # Preserve source structure
          )

          # Create documentation structure
          FileUtils.mkdir_p(["source/guides", "source/api", "docs"])
          
          create_markdown_file("source/index.md", "# Documentation\n\nWelcome to our docs!")
          create_markdown_file("source/guides/getting-started.md", "# Getting Started\n\nInstallation guide.")
          create_markdown_file("source/guides/advanced.md", "# Advanced Usage\n\nAdvanced features.")
          create_markdown_file("source/api/reference.md", "# API Reference\n\nComplete API docs.")

          # Publish all documentation
          md_files = Dir.glob("source/**/*.md")
          expect {
            Mint::Commandline.publish!(md_files, config: config)
          }.not_to raise_error

          # Verify structure is maintained
          expect(File.exist?("docs/source/index.html")).to be true
          expect(File.exist?("docs/source/guides/getting-started.html")).to be true
          expect(File.exist?("docs/source/guides/advanced.html")).to be true
          expect(File.exist?("docs/source/api/reference.html")).to be true

          # Verify content
          index_content = File.read("docs/source/index.html")
          expect(index_content).to include("Welcome to our docs!")
        end
      end

      describe "blog workflow" do
        it "can manage a simple blog" do
          # Set up blog configuration
          config = Mint::Config.with_defaults(
            layout_name: "default", 
            destination_directory: Pathname.new("blog"),
            preserve_structure: true  # Preserve posts/ structure
          )

          # Create blog structure
          FileUtils.mkdir_p(["posts", "blog"])
          
          create_markdown_file("index.md", "# My Blog\n\nWelcome to my thoughts!")
          create_markdown_file("posts/2023-01-01-hello-world.md", "# Hello World\n\nMy first post.")
          create_markdown_file("posts/2023-02-15-update.md", "# February Update\n\nWhat I've been up to.")

          # Publish blog
          blog_files = ["index.md"] + Dir.glob("posts/*.md")
          expect {
            Mint::Commandline.publish!(blog_files, config: config)
          }.not_to raise_error

          # Verify blog structure
          expect(File.exist?("blog/index.html")).to be true
          expect(File.exist?("blog/posts/2023-01-01-hello-world.html")).to be true
          expect(File.exist?("blog/posts/2023-02-15-update.html")).to be true
        end
      end

      describe "error recovery workflows" do
        it "can recover from and fix common mistakes" do
          create_markdown_file("test.md", "# Test")

          # Test error when nonexistent style is specified
          expect {
            Mint::Commandline.publish!(["test.md"], config: Mint::Config.with_defaults(style_name: "nonexistent"))
          }.to raise_error(Mint::StyleNotFoundException)

          # Recovery: Use existing layout
          expect {
            Mint::Commandline.publish!(["test.md"], config: Mint::Config.with_defaults(layout_name: "default"))
          }.not_to raise_error

          expect(File.exist?("test.html")).to be true
        end

        it "handles corrupted configuration gracefully" do
          # Create corrupted config file
          FileUtils.mkdir_p(".mint")
          File.write(".mint/config.toml", "invalid = toml content [")

          create_markdown_file("test.md", "# Test")

          # Should still work with explicit config
          expect {
            Mint::Commandline.publish!(["test.md"], config: Mint::Config.defaults)
          }.not_to raise_error

          expect(File.exist?("test.html")).to be true
        end
      end

      describe "performance with large projects" do
        it "handles many files efficiently" do
          # Create many files
          files = []
          (1..50).each do |i|
            filename = "doc#{i}.md"
            create_markdown_file(filename, "# Document #{i}\n\nContent for document #{i}.")
            files << filename
          end

          config = Mint::Config.defaults

          # Measure performance
          start_time = Time.now
          expect {
            Mint::Commandline.publish!(files, config: config)
          }.not_to raise_error
          end_time = Time.now

          # Should complete in reasonable time (less than 30 seconds for 50 files)
          expect(end_time - start_time).to be < 30

          # Verify all files were processed
          (1..50).each do |i|
            expect(File.exist?("doc#{i}.html")).to be true
          end
        end
      end
    end
  end
end