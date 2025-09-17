require "spec_helper"

RSpec.describe "Bin Script Integration" do
  describe "mint executable" do
    let(:mint_bin) { File.expand_path("../../../bin/mint", __FILE__) }
    let(:project_root) { File.expand_path("../../..", __FILE__) }
    
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          # Copy bin scripts to test directory for isolation
          FileUtils.cp_r("#{project_root}/bin", ".")
          FileUtils.cp_r("#{project_root}/lib", ".")
          
          # Make sure bin script is executable
          FileUtils.chmod(0755, "bin/mint")
          example.run
        end
      end

      describe "basic command functionality" do
        it "shows help when run with no arguments" do
          result = run_command("ruby", "bin/mint")
          
          expect(result.success?).to be true
          expect(result.stdout).to include("Usage:")
        end

        it "shows help with --help flag" do
          result = run_command("ruby", "bin/mint", "--help")
          
          expect(result.stdout).to include("Usage: mint files [options]")
          expect(result.stdout).to include("--template")
          expect(result.stdout).to include("--layout")
          expect(result.stdout).to include("--style")
        end
      end

      describe "file processing" do
        it "publishes markdown files via CLI" do
          create_template_directory("default")
          create_markdown_path("test.md", "# Hello CLI\n\nThis works!")
          
          result = run_command({}, "ruby", "bin/mint", "test.md")
          
          expect(result.success?).to be true
          expect(File.exist?("test.html")).to be true
          
          content = File.read("test.html")
          expect(content).to include("<h1>Hello CLI</h1>")
          expect(content).to include("<p>This works!</p>")
        end

        it "handles multiple files" do
          create_template_directory("default")
          create_markdown_path("doc1.md", "# Document 1")
          create_markdown_path("doc2.md", "# Document 2")
          
          result = run_command({}, "ruby", "bin/mint", "doc1.md", "doc2.md")
          
          expect(result.success?).to be true
          expect(File.exist?("doc1.html")).to be true
          expect(File.exist?("doc2.html")).to be true
        end

        it "respects template options" do
          create_template_directory("default")
          create_template_directory("custom")
          create_markdown_path("styled.md", "# Custom Style")
          
          result = run_command({}, "ruby", "bin/mint", "--template", "custom", "styled.md")
          
          # Should succeed even if template doesn't exist (will use default)
          expect(result.success?).to be true
          expect(File.exist?("styled.html")).to be true
        end
      end

      describe "error handling and edge cases" do
        it "handles missing files gracefully" do
          create_template_directory("default")
          result = run_command("ruby", "bin/mint", "nonexistent.md")

          expect(result.success?).to be false
          expect(result.stderr).to include("Error:")
        end

        it "handles malformed arguments" do
          result = run_command("ruby", "bin/mint", "--invalid-flag", "test.md")

          expect(result.success?).to be false
        end

        it "provides helpful error messages" do
          create_template_directory("default")
          result = run_command("ruby", "bin/mint", "nonexistent.md")

          expect(result.stderr).to include("Error:")
        end
      end

      describe "output formatting and verbosity" do
        it "produces clean output for normal operations" do
          create_template_directory("default")
          create_markdown_path("test.md", "# Test")
          
          result = run_command({}, "ruby", "bin/mint", "test.md")
          
          expect(result.success?).to be true
          # Should not have excessive debug output
          expect(result.stdout.lines.length).to be < 10
        end
      end

      describe "integration with system tools" do
        it "exits with appropriate status codes" do
          create_template_directory("default")
          create_markdown_path("success.md", "# Success")
          
          success_result = run_command({}, "ruby", "bin/mint", "success.md")
          expect(success_result.exit_code).to eq(0)

          failure_result = run_command({}, "ruby", "bin/mint", "nonexistent.md")
          expect(failure_result.exit_code).not_to eq(0)
        end
      end
    end
  end
end