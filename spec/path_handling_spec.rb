require "spec_helper"

RSpec.describe "Path Handling in Workspace.publish!" do
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
        create_markdown_path("docs/readme.md", "# Documentation")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("docs/readme.md")], config)
        workspace.publish!
        
        expect(File.exist?("output/docs/readme.html")).to be true
        expect(File.exist?("output/readme.html")).to be false
      end

      it "preserves multi-level directory structure" do
        FileUtils.mkdir_p(["src/guides/advanced", "build"])
        create_markdown_path("src/guides/advanced/config.md", "# Advanced Configuration")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("build"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("src/guides/advanced/config.md")], config)
        workspace.publish!
        
        expect(File.exist?("build/src/guides/advanced/config.html")).to be true
        expect(File.exist?("build/config.html")).to be false
      end

      it "handles files in root directory" do
        create_markdown_path("index.md", "# Home Page")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("site"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("index.md")], config)
        workspace.publish!
        
        expect(File.exist?("site/index.html")).to be true
      end

      it "handles nested destination directories" do
        FileUtils.mkdir_p("content")
        create_markdown_path("content/about.md", "# About Us")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("public/website"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("content/about.md")], config)
        workspace.publish!
        
        expect(File.exist?("public/website/content/about.html")).to be true
        expect(Dir.exist?("public/website/content")).to be true
      end
    end

    describe "complex directory structures" do
      it "handles deeply nested source with shallow destination" do
        FileUtils.mkdir_p(["project/src/docs/api/v1", "api-docs"])
        create_markdown_path("project/src/docs/api/v1/users.md", "# Users API")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("api-docs"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("project/src/docs/api/v1/users.md")], config)
        workspace.publish!
        
        expect(File.exist?("api-docs/project/src/docs/api/v1/users.html")).to be true
      end

      it "handles multiple files with different nesting levels" do
        FileUtils.mkdir_p(["src", "src/components", "src/pages/admin", "build"])
        
        create_markdown_path("src/readme.md", "# Project README")
        create_markdown_path("src/components/button.md", "# Button Component")  
        create_markdown_path("src/pages/admin/dashboard.md", "# Admin Dashboard")
        
        files = [
          "src/readme.md",
          "src/components/button.md", 
          "src/pages/admin/dashboard.md"
        ]
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("build"), preserve_structure: true)
        
        workspace = Mint::Workspace.new(files.map {|f| Pathname.new(f) }, config)
        workspace.publish!
        
        expect(File.exist?("build/readme.html")).to be true
        expect(File.exist?("build/components/button.html")).to be true
        expect(File.exist?("build/pages/admin/dashboard.html")).to be true
      end
    end

    describe "edge cases" do
      it "handles files with dots in directory names" do
        FileUtils.mkdir_p(["v1.0/docs", "output"])
        create_markdown_path("v1.0/docs/changelog.md", "# Changelog")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("v1.0/docs/changelog.md")], config)
        workspace.publish!
        
        expect(File.exist?("output/v1.0/docs/changelog.html")).to be true
      end

      it "handles files with spaces in directory names" do
        FileUtils.mkdir_p(["My Documents/Notes", "website"])
        create_markdown_path("My Documents/Notes/ideas.md", "# Ideas")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("website"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("My Documents/Notes/ideas.md")], config)
        workspace.publish!
        
        expect(File.exist?("website/My Documents/Notes/ideas.html")).to be true
      end

      it "handles symlinked directories" do
        FileUtils.mkdir_p(["real-content", "output"])
        create_markdown_path("real-content/page.md", "# Page")
        
        # Create symlink (skip if not supported)
        begin
          File.symlink("real-content", "linked-content")
          
          config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
          workspace = Mint::Workspace.new([Pathname.new("linked-content/page.md")], config)
          workspace.publish!
          
          expect(File.exist?("output/linked-content/page.html")).to be true
        rescue NotImplementedError
          skip "Symlinks not supported on this system"
        end
      end

      it "handles current directory references" do
        FileUtils.mkdir_p(["docs", "site"])
        create_markdown_path("docs/manual.md", "# Manual")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("./site"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("./docs/manual.md")], config)
        workspace.publish!
        
        expect(File.exist?("site/docs/manual.html")).to be true
      end

      it "handles parent directory references" do
        FileUtils.mkdir_p(["project/content", "project/build", "output"])
        create_markdown_path("project/content/info.md", "# Information")
        
        Dir.chdir("project") do
          config = Mint::Config.with_defaults(destination_directory: Pathname.new("../output"), preserve_structure: true)
          workspace = Mint::Workspace.new([Pathname.new("content/info.md")], config)
          workspace.publish!
        end
        
        expect(File.exist?("output/content/info.html")).to be true
      end
    end

    describe "destination directory creation" do
      it "creates missing destination directories automatically" do
        create_markdown_path("test.md", "# Test")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("deeply/nested/output/dir"))
        workspace = Mint::Workspace.new([Pathname.new("test.md")], config)
        workspace.publish!
        
        expect(File.exist?("deeply/nested/output/dir/test.html")).to be true
        expect(Dir.exist?("deeply/nested/output/dir")).to be true
      end

      it "creates missing intermediate directories for nested sources" do
        FileUtils.mkdir_p("src/a/b/c")
        create_markdown_path("src/a/b/c/deep.md", "# Deep File")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("src/a/b/c/deep.md")], config)
        workspace.publish!
        
        expect(File.exist?("output/src/a/b/c/deep.html")).to be true
        expect(Dir.exist?("output/src/a/b/c")).to be true
      end
    end

    describe "path sanitization" do
      it "preserves valid special characters in paths" do
        FileUtils.mkdir_p(["docs-2023", "output"])
        create_markdown_path("docs-2023/v1.0_final.md", "# Version 1.0")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"), preserve_structure: true)
        workspace = Mint::Workspace.new([Pathname.new("docs-2023/v1.0_final.md")], config)
        workspace.publish!
        
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
          create_markdown_path(file, "# Document #{i + 1}")
        end
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("public"), preserve_structure: true)
        
        workspace = Mint::Workspace.new(files.map {|f| Pathname.new(f) }, config)
        workspace.publish!
        
        # Verify all files maintain their structure (with common "content" prefix dropped by autodrop)
        expect(File.exist?("public/blog/2023/hello-world.html")).to be true
        expect(File.exist?("public/docs/guides/getting-started.html")).to be true
        expect(File.exist?("public/docs/guides/advanced.html")).to be true
        expect(File.exist?("public/pages/about.html")).to be true
        expect(File.exist?("public/pages/contact.html")).to be true
      end
    end
  end
end