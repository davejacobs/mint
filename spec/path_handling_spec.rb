require "spec_helper"

RSpec.describe "Path Handling in Mint.publish!" do
  context "in isolated environment" do
    around(:each) do |example|
      in_temp_dir do |dir|
        @test_dir = dir
        create_template_directory("default")
        example.run
      end
    end

    describe "relative path preservation (with preserve_structure: true)" do
      it "preserves single-level directory structure" do
        FileUtils.mkdir_p(["docs", "output"])
        create_markdown_file("docs/readme.md", "# Documentation")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"), preserve_structure: true)
        Mint.publish!("docs/readme.md", config: config)
        
        expect(File.exist?("output/docs/readme.html")).to be true
        expect(File.exist?("output/readme.html")).to be false
      end

      it "preserves multi-level directory structure" do
        FileUtils.mkdir_p(["src/guides/advanced", "build"])
        create_markdown_file("src/guides/advanced/config.md", "# Advanced Configuration")
        
        config = Mint::Config.new(destination_directory: Pathname.new("build"), preserve_structure: true)
        Mint.publish!("src/guides/advanced/config.md", config: config)
        
        expect(File.exist?("build/src/guides/advanced/config.html")).to be true
        expect(File.exist?("build/config.html")).to be false
      end

      it "handles files in root directory" do
        create_markdown_file("index.md", "# Home Page")
        
        config = Mint::Config.new(destination_directory: Pathname.new("site"), preserve_structure: true)
        Mint.publish!("index.md", config: config)
        
        expect(File.exist?("site/index.html")).to be true
      end

      it "handles nested destination directories" do
        FileUtils.mkdir_p("content")
        create_markdown_file("content/about.md", "# About Us")
        
        config = Mint::Config.new(destination_directory: Pathname.new("public/website"), preserve_structure: true)
        Mint.publish!("content/about.md", config: config)
        
        expect(File.exist?("public/website/content/about.html")).to be true
        expect(Dir.exist?("public/website/content")).to be true
      end
    end

    describe "root directory effects on paths" do
      it "respects custom root directory" do
        FileUtils.mkdir_p(["source/pages", "dist"])
        create_markdown_file("source/pages/home.md", "# Home")
        
        config = Mint::Config.new(
          working_directory: Pathname.new("source"),
          destination_directory: Pathname.new("../dist"),  # Relative to root directory
          preserve_structure: true
        )
        Mint.publish!("source/pages/home.md", config: config)
        
        expect(File.exist?("dist/pages/home.html")).to be true
        expect(File.exist?("dist/source/pages/home.html")).to be false
      end

      it "handles root directory same as source directory" do
        FileUtils.mkdir_p(["content/posts", "output"])
        create_markdown_file("content/posts/article.md", "# Article")
        
        config = Mint::Config.new(
          working_directory: Pathname.new("content/posts"),
          destination_directory: Pathname.new("../../output"),  # Relative to root directory
          preserve_structure: true
        )
        Mint.publish!("content/posts/article.md", config: config)
        
        expect(File.exist?("output/article.html")).to be true
        expect(File.exist?("output/posts/article.html")).to be false
      end

      it "handles absolute source paths with relative destinations" do
        FileUtils.mkdir_p(["documents", "website"])
        doc_file = File.expand_path("documents/guide.md")
        create_markdown_file("documents/guide.md", "# User Guide")
        
        config = Mint::Config.new(destination_directory: Pathname.new("website"), preserve_structure: true)
        Mint.publish!(doc_file, config: config)
        
        expect(File.exist?("website/documents/guide.html")).to be true
      end
    end

    describe "complex directory structures" do
      it "handles deeply nested source with shallow destination" do
        FileUtils.mkdir_p(["project/src/docs/api/v1", "api-docs"])
        create_markdown_file("project/src/docs/api/v1/users.md", "# Users API")
        
        config = Mint::Config.new(destination_directory: Pathname.new("api-docs"), preserve_structure: true)
        Mint.publish!("project/src/docs/api/v1/users.md", config: config)
        
        expect(File.exist?("api-docs/project/src/docs/api/v1/users.html")).to be true
      end

      it "handles multiple files with different nesting levels" do
        FileUtils.mkdir_p(["src", "src/components", "src/pages/admin", "build"])
        
        create_markdown_file("src/readme.md", "# Project README")
        create_markdown_file("src/components/button.md", "# Button Component")  
        create_markdown_file("src/pages/admin/dashboard.md", "# Admin Dashboard")
        
        files = [
          "src/readme.md",
          "src/components/button.md", 
          "src/pages/admin/dashboard.md"
        ]
        
        config = Mint::Config.new(destination_directory: Pathname.new("build"), preserve_structure: true)
        
        files.each {|file| Mint.publish!(file, config: config) }
        
        expect(File.exist?("build/src/readme.html")).to be true
        expect(File.exist?("build/src/components/button.html")).to be true
        expect(File.exist?("build/src/pages/admin/dashboard.html")).to be true
      end
    end

    describe "edge cases" do
      it "handles files with dots in directory names" do
        FileUtils.mkdir_p(["v1.0/docs", "output"])
        create_markdown_file("v1.0/docs/changelog.md", "# Changelog")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"), preserve_structure: true)
        Mint.publish!("v1.0/docs/changelog.md", config: config)
        
        expect(File.exist?("output/v1.0/docs/changelog.html")).to be true
      end

      it "handles files with spaces in directory names" do
        FileUtils.mkdir_p(["My Documents/Notes", "website"])
        create_markdown_file("My Documents/Notes/ideas.md", "# Ideas")
        
        config = Mint::Config.new(destination_directory: Pathname.new("website"), preserve_structure: true)
        Mint.publish!("My Documents/Notes/ideas.md", config: config)
        
        expect(File.exist?("website/My Documents/Notes/ideas.html")).to be true
      end

      it "handles symlinked directories" do
        FileUtils.mkdir_p(["real-content", "output"])
        create_markdown_file("real-content/page.md", "# Page")
        
        # Create symlink (skip if not supported)
        begin
          File.symlink("real-content", "linked-content")
          
          config = Mint::Config.new(destination_directory: Pathname.new("output"), preserve_structure: true)
          Mint.publish!("linked-content/page.md", config: config)
          
          expect(File.exist?("output/linked-content/page.html")).to be true
        rescue NotImplementedError
          skip "Symlinks not supported on this system"
        end
      end

      it "handles current directory references" do
        FileUtils.mkdir_p(["docs", "site"])
        create_markdown_file("docs/manual.md", "# Manual")
        
        config = Mint::Config.new(destination_directory: Pathname.new("./site"), preserve_structure: true)
        Mint.publish!("./docs/manual.md", config: config)
        
        expect(File.exist?("site/docs/manual.html")).to be true
      end

      it "handles parent directory references" do
        FileUtils.mkdir_p(["project/content", "project/build", "output"])
        create_markdown_file("project/content/info.md", "# Information")
        
        Dir.chdir("project") do
          config = Mint::Config.new(destination_directory: Pathname.new("../output"), preserve_structure: true)
          Mint.publish!("content/info.md", config: config)
        end
        
        expect(File.exist?("output/content/info.html")).to be true
      end
    end

    describe "destination directory creation" do
      it "creates missing destination directories automatically" do
        create_markdown_file("test.md", "# Test")
        
        config = Mint::Config.new(destination_directory: Pathname.new("deeply/nested/output/dir"))
        Mint.publish!("test.md", config: config)
        
        expect(File.exist?("deeply/nested/output/dir/test.html")).to be true
        expect(Dir.exist?("deeply/nested/output/dir")).to be true
      end

      it "creates missing intermediate directories for nested sources" do
        FileUtils.mkdir_p("src/a/b/c")
        create_markdown_file("src/a/b/c/deep.md", "# Deep File")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"), preserve_structure: true)
        Mint.publish!("src/a/b/c/deep.md", config: config)
        
        expect(File.exist?("output/src/a/b/c/deep.html")).to be true
        expect(Dir.exist?("output/src/a/b/c")).to be true
      end
    end

    describe "path sanitization" do
      it "preserves valid special characters in paths" do
        FileUtils.mkdir_p(["docs-2023", "output"])
        create_markdown_file("docs-2023/v1.0_final.md", "# Version 1.0")
        
        config = Mint::Config.new(destination_directory: Pathname.new("output"), preserve_structure: true)
        Mint.publish!("docs-2023/v1.0_final.md", config: config)
        
        expect(File.exist?("output/docs-2023/v1.0_final.html")).to be true
      end
    end

    describe "multiple file processing with paths" do
      it "processes multiple files maintaining their relative structure" do
        # Create a realistic project structure
        FileUtils.mkdir_p([
          "content/blog/2023", 
          "content/docs/guides",
          "content/pages",
          "public"
        ])
        
        files = [
          "content/blog/2023/hello-world.md",
          "content/docs/guides/getting-started.md", 
          "content/docs/guides/advanced.md",
          "content/pages/about.md",
          "content/pages/contact.md"
        ]
        
        files.each_with_index do |file, i|
          create_markdown_file(file, "# Document #{i + 1}")
        end
        
        config = Mint::Config.new(destination_directory: Pathname.new("public"), preserve_structure: true)
        
        files.each {|file| Mint.publish!(file, config: config) }
        
        # Verify all files maintain their structure
        expect(File.exist?("public/content/blog/2023/hello-world.html")).to be true
        expect(File.exist?("public/content/docs/guides/getting-started.html")).to be true
        expect(File.exist?("public/content/docs/guides/advanced.html")).to be true
        expect(File.exist?("public/content/pages/about.html")).to be true
        expect(File.exist?("public/content/pages/contact.html")).to be true
      end
    end
  end
end