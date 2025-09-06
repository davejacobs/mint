require "spec_helper"

RSpec.describe "Flattened Path Handling (default behavior)" do
  context "in isolated environment" do
    around(:each) do |example|
      in_temp_dir do |dir|
        @test_dir = dir
        create_template_directory("default")
        example.run
      end
    end

    describe "default flattened behavior" do
      it "places files from nested directories directly in destination" do
        FileUtils.mkdir_p(["docs/guides", "output"])
        create_markdown_file("docs/guides/setup.md", "# Setup Guide")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"))
        Mint.publish!("docs/guides/setup.md", config: config)
        
        # File should be flattened to output directory
        expect(File.exist?("output/setup.html")).to be true
        expect(File.exist?("output/docs/guides/setup.html")).to be false
      end

      it "handles multiple files from different nested levels" do
        FileUtils.mkdir_p(["src", "src/components", "src/pages/admin", "build"])
        
        create_markdown_file("src/readme.md", "# Project README")
        create_markdown_file("src/components/button.md", "# Button Component")  
        create_markdown_file("src/pages/admin/dashboard.md", "# Admin Dashboard")
        
        files = [
          "src/readme.md",
          "src/components/button.md", 
          "src/pages/admin/dashboard.md"
        ]
        
        config = Mint::Config.new(destination_directory: Pathname.new("build"))
        
        files.each {|file| Mint.publish!(file, config: config) }
        
        # All files should be flattened to build directory
        expect(File.exist?("build/readme.html")).to be true
        expect(File.exist?("build/button.html")).to be true
        expect(File.exist?("build/dashboard.html")).to be true
        
        # Should not preserve directory structure
        expect(File.exist?("build/src/readme.html")).to be false
        expect(File.exist?("build/src/components/button.html")).to be false
        expect(File.exist?("build/src/pages/admin/dashboard.html")).to be false
      end

      it "handles files with same basename from different directories" do
        FileUtils.mkdir_p(["docs/v1", "docs/v2", "output"])
        
        create_markdown_file("docs/v1/index.md", "# V1 Index")
        create_markdown_file("docs/v2/index.md", "# V2 Index")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"))
        
        # Process files separately to see collision behavior
        Mint.publish!("docs/v1/index.md", config: config)
        Mint.publish!("docs/v2/index.md", config: config)
        
        # Only one index.html should exist (last one wins)
        expect(File.exist?("output/index.html")).to be true
        
        # Check that it's the V2 content (last one processed)
        content = File.read("output/index.html")
        expect(content).to include("V2 Index")
      end

      it "works with commandline batch processing" do
        FileUtils.mkdir_p(["content/posts", "content/pages", "site"])
        
        create_markdown_file("content/posts/article1.md", "# Article 1")
        create_markdown_file("content/posts/article2.md", "# Article 2")
        create_markdown_file("content/pages/about.md", "# About")
        
        files = [
          "content/posts/article1.md",
          "content/posts/article2.md", 
          "content/pages/about.md"
        ]
        
        config = Mint::Config.new(destination_directory: Pathname.new("site"))
        Mint::Commandline.publish!(files, config: config)
        
        # All files flattened to site directory
        expect(File.exist?("site/article1.html")).to be true
        expect(File.exist?("site/article2.html")).to be true
        expect(File.exist?("site/about.html")).to be true
        
        # No nested structure
        expect(File.exist?("site/content/posts/article1.html")).to be false
        expect(File.exist?("site/content/pages/about.html")).to be false
      end

      it "works with different root and destination directories" do
        FileUtils.mkdir_p(["source/docs", "public"])
        
        create_markdown_file("source/docs/guide.md", "# User Guide")
        
        config = Mint::Config.new(
          working_directory: Pathname.new("source"),
          destination_directory: Pathname.new("../public")
        )
        
        Mint.publish!("source/docs/guide.md", config: config)
        
        # File should be flattened in public directory
        expect(File.exist?("public/guide.html")).to be true
        expect(File.exist?("public/docs/guide.html")).to be false
      end

      it "maintains original behavior for files in root directory" do
        FileUtils.mkdir_p("output")
        create_markdown_file("index.md", "# Home Page")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"))
        Mint.publish!("index.md", config: config)
        
        expect(File.exist?("output/index.html")).to be true
      end

      it "works with external style mode" do
        FileUtils.mkdir_p(["docs", "site"])
        create_markdown_file("docs/manual.md", "# Manual")
        
        config = Mint::Config.new(
          destination_directory: Pathname.new("site"),
          style_mode: :external
        )
        
        Mint::Commandline.publish!(["docs/manual.md"], config: config)
        
        expect(File.exist?("site/manual.html")).to be true  # Flattened
        expect(File.exist?("site/style.css")).to be true    # Style in destination
        expect(File.exist?("site/docs/manual.html")).to be false
      end
    end
  end
end