require "spec_helper"

RSpec.describe "Mint::Commandline.publish! Path Integration" do
  context "in isolated environment" do
    around(:each) do |example|
      in_temp_dir do |dir|
        @test_dir = dir
        create_template_directory("default")
        example.run
      end
    end

    describe "batch file processing with mixed paths" do
      it "handles mixed relative and nested paths in single batch" do
        FileUtils.mkdir_p(["docs/api", "content/blog", "output"])
        
        files = [
          Pathname.new("readme.md"),
          Pathname.new("docs/installation.md"), 
          Pathname.new("docs/api/reference.md"),
          Pathname.new("content/blog/post1.md")
        ]
        
        files.each_with_index do |file, i|
          create_markdown_path(file, "# Document #{i + 1}")
        end
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        Mint::Commandline.publish!(files, config: config)
        
        expect(File.exist?("output/readme.html")).to be true
        expect(File.exist?("output/docs/installation.html")).to be true
        expect(File.exist?("output/docs/api/reference.html")).to be true
        expect(File.exist?("output/content/blog/post1.html")).to be true
      end

      it "handles glob patterns maintaining directory structure" do
        FileUtils.mkdir_p(["guides/beginner", "guides/advanced", "tutorials", "site"])
        
        create_markdown_path("guides/beginner/basics.md", "# Basics")
        create_markdown_path("guides/beginner/setup.md", "# Setup") 
        create_markdown_path("guides/advanced/config.md", "# Configuration")
        create_markdown_path("tutorials/first-steps.md", "# First Steps")
        
        files = Dir.glob("**/*.md").map {|f| Pathname.new(f) }
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("site"), preserve_structure: true)
        
        Mint::Commandline.publish!(files, config: config)
        
        expect(File.exist?("site/guides/beginner/basics.html")).to be true
        expect(File.exist?("site/guides/beginner/setup.html")).to be true
        expect(File.exist?("site/guides/advanced/config.html")).to be true
        expect(File.exist?("site/tutorials/first-steps.html")).to be true
      end
    end

    describe "root directory configuration effects" do
      it "processes files with explicit root directory in batch" do
        FileUtils.mkdir_p(["source/pages", "source/assets", "build"])
        
        files = [
          Pathname.new("source/pages/home.md"),
          Pathname.new("source/pages/about.md"),
          Pathname.new("source/assets/docs.md")
        ]
        
        files.each_with_index do |file, i|
          create_markdown_path(file, "# Page #{i + 1}")
        end
        
        config = Mint::Config.with_defaults(
          working_directory: Pathname.new("source"),
          destination_directory: Pathname.new("../build"),  # Relative to root directory
          preserve_structure: true
        )
        
        Mint::Commandline.publish!(files, config: config)
        
        # Should strip 'source/' prefix due to root directory
        expect(File.exist?("build/pages/home.html")).to be true
        expect(File.exist?("build/pages/about.html")).to be true
        expect(File.exist?("build/assets/docs.html")).to be true
        
        # Should not have source/ prefix
        expect(File.exist?("build/source/pages/home.html")).to be false
      end
    end

    describe "style file placement with paths" do
      it "creates style files in correct destination with external mode" do
        FileUtils.mkdir_p(["content", "public"])
        create_markdown_path("content/article.md", "# Article")
        
        config = Mint::Config.with_defaults(
          destination_directory: Pathname.new("public"),
          style_mode: :external,
          preserve_structure: true
        )
        
        Mint::Commandline.publish!([Pathname.new("content/article.md")], config: config)
        
        expect(File.exist?("public/content/article.html")).to be true
        expect(File.exist?("public/style.css")).to be true
      end

      it "handles style destination directory with nested sources" do
        FileUtils.mkdir_p(["src/docs", "web/pages", "web/assets"])
        create_markdown_path("src/docs/guide.md", "# Guide")
        
        config = Mint::Config.with_defaults(
          destination_directory: Pathname.new("web/pages"),
          style_destination_directory: Pathname.new("web/assets"),
          style_mode: :external,
          preserve_structure: true
        )
        
        Mint::Commandline.publish!([Pathname.new("src/docs/guide.md")], config: config)
        
        expect(File.exist?("web/pages/src/docs/guide.html")).to be true
        expect(File.exist?("web/pages/web/assets/style.css")).to be true
      end
    end

    describe "error handling with paths" do
      it "handles nonexistent source files gracefully" do
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        
        expect {
          Mint::Commandline.publish!([Pathname.new("nonexistent/file.md")], config: config)
        }.to raise_error(Errno::ENOENT)
      end

      it "creates deeply nested destination directories as needed" do
        create_markdown_path("test.md", "# Test")
        
        config = Mint::Config.with_defaults(
          destination_directory: Pathname.new("very/deeply/nested/output/directory")
        )
        
        expect {
          Mint::Commandline.publish!([Pathname.new("test.md")], config: config)
        }.not_to raise_error
        
        expect(File.exist?("very/deeply/nested/output/directory/test.html")).to be true
      end
    end

    describe "cross-linking with preserved paths" do
      it "transforms markdown links correctly with nested paths" do
        FileUtils.mkdir_p(["docs/guides", "docs/api", "site"])
        
        # Create files with cross-references
        create_markdown_path("docs/guides/intro.md", 
          "# Introduction\n\nSee also [API Reference](../api/reference.md).")
        create_markdown_path("docs/api/reference.md",
          "# API Reference\n\nBack to [Introduction](../guides/intro.md).")
        
        files = [Pathname.new("docs/guides/intro.md"), Pathname.new("docs/api/reference.md")]
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("site"), preserve_structure: true)
        
        Mint::Commandline.publish!(files, config: config)
        
        # Check that links were transformed
        intro_content = File.read("site/guides/intro.html")
        expect(intro_content).to include("../api/reference.html")
        
        api_content = File.read("site/api/reference.html") 
        expect(api_content).to include("../guides/intro.html")
      end
    end

    describe "real-world scenarios" do
      it "handles documentation site structure" do
        # Simulate hugo/jekyll-style structure
        FileUtils.mkdir_p([
          "content/posts/2023",
          "content/docs/v1.0", 
          "content/about",
          "public"
        ])
        
        files = [
          Pathname.new("content/posts/2023/welcome.md"),
          Pathname.new("content/docs/v1.0/getting-started.md"),
          Pathname.new("content/docs/v1.0/api.md"), 
          Pathname.new("content/about/index.md")
        ]
        
        files.each_with_index do |file, i|
          create_markdown_path(file, "# Content #{i + 1}")
        end
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("public"), preserve_structure: true)
        Mint::Commandline.publish!(files, config: config)
        
        expect(File.exist?("public/posts/2023/welcome.html")).to be true
        expect(File.exist?("public/docs/v1.0/getting-started.html")).to be true
        expect(File.exist?("public/docs/v1.0/api.html")).to be true
        expect(File.exist?("public/about/index.html")).to be true
      end

      it "handles monorepo documentation structure" do
        # Simulate monorepo with multiple packages
        FileUtils.mkdir_p([
          "packages/core/docs",
          "packages/ui/docs", 
          "packages/utils/docs",
          "docs-site"
        ])
        
        files = [
          Pathname.new("packages/core/docs/api.md"),
          Pathname.new("packages/ui/docs/components.md"),
          Pathname.new("packages/utils/docs/helpers.md")
        ]
        
        files.each_with_index do |file, i|
          create_markdown_path(file, "# Package Documentation #{i + 1}")
        end
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("docs-site"), preserve_structure: true)
        Mint::Commandline.publish!(files, config: config)
        
        expect(File.exist?("docs-site/core/docs/api.html")).to be true
        expect(File.exist?("docs-site/ui/docs/components.html")).to be true
        expect(File.exist?("docs-site/utils/docs/helpers.html")).to be true
      end
    end
  end
end