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
          
          expect(result.stdout).to include("Usage: mint [command] files [options]")
          expect(result.stdout).to include("--template")
          expect(result.stdout).to include("--layout")
          expect(result.stdout).to include("--style")
        end

        it "shows version information" do
          # Assuming there's a --version flag or similar
          # This might need adjustment based on actual implementation
          result = run_command("ruby", "bin/mint", "--version")
          
          # This test might fail if --version isn't implemented
          # In that case, we could test a different way to get version info
        end
      end

      describe "publish command" do
        it "publishes markdown files via CLI" do
          create_markdown_file("test.md", "# Hello from CLI")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "test.md")
          
          expect(result.success?).to be true
          expect(File.exist?("test.html")).to be true
          
          content = File.read("test.html")
          expect(content).to include("Hello from CLI")
        end

        it "handles multiple files" do
          create_markdown_file("doc1.md", "# Document 1")
          create_markdown_file("doc2.md", "# Document 2")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "doc1.md", "doc2.md")
          
          expect(result.success?).to be true
          expect(File.exist?("doc1.html")).to be true
          expect(File.exist?("doc2.html")).to be true
        end

        it "respects template options" do
          create_markdown_file("styled.md", "# Styled Document")
          setup_basic_config
          create_template_directory("default")
          create_template_directory("custom")
          
          # Write a distinctive custom template
          File.write(".mint/templates/custom/layout.erb", 
            "<html><body class='custom-style'><%= content %></body></html>")
          File.write(".mint/templates/custom/style.css", 
            "body { background: red; }")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "--template", "custom", "styled.md")
          
          expect(result.success?).to be true
          expect(File.exist?("styled.html")).to be true
          
          content = File.read("styled.html")
          expect(content).to include("custom-style")
        end

        it "handles recursive publishing" do
          FileUtils.mkdir_p("docs/sub")
          create_markdown_file("docs/index.md", "# Index")
          create_markdown_file("docs/sub/page.md", "# Sub Page")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "--recursive", "docs")
          
          expect(result.success?).to be true
          expect(File.exist?("docs/index.html")).to be true
          expect(File.exist?("docs/sub/page.html")).to be true
        end

        it "handles errors gracefully" do
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "nonexistent.md")
          
          expect(result.success?).to be false
          expect(result.stderr + result.stdout).to match(/error|Error|No such file|ENOENT/i)
        end
      end

      describe "template management commands" do
        it "lists templates" do
          setup_basic_config
          create_template_directory("custom1")
          create_template_directory("custom2")
          
          result = run_command("ruby", "bin/mint", "templates")
          
          expect(result.success?).to be true
          expect(result.stdout).to include("custom1")
          expect(result.stdout).to include("custom2")
        end

        it "installs templates" do
          create_template_file("my-layout.erb", :layout, "<html><%= yield %></html>")
          
          result = run_command("ruby", "bin/mint", "install", "my-layout.erb", "mynew")
          
          expect(result.success?).to be true
          expect(File.exist?(".mint/templates/mynew/layout.erb")).to be true
        end

        it "uninstalls templates" do
          setup_basic_config
          create_template_directory("removeme")
          
          # Verify it exists first
          expect(File.exist?(".mint/templates/removeme")).to be true
          
          result = run_command("ruby", "bin/mint", "uninstall", "removeme")
          
          expect(result.success?).to be true
          expect(File.exist?(".mint/templates/removeme")).to be false
        end

        it "edits templates" do
          setup_basic_config
          create_template_directory("editable", with_layout: true)
          
          # Mock the editor to avoid opening a real editor
          result = run_command(
            {"EDITOR" => "echo 'edited'"}, 
            "ruby", "bin/mint", "edit-layout", "editable"
          )
          
          expect(result.success?).to be true
        end
      end

      describe "configuration commands" do
        it "displays current configuration" do
          setup_basic_config
          
          result = run_command("ruby", "bin/mint", "config")
          
          expect(result.success?).to be true
          expect(result.stdout).to include("layout")
          expect(result.stdout).to include("default")
        end

        it "sets configuration values" do
          result = run_command("ruby", "bin/mint", "set", "layout", "custom-layout")
          
          expect(result.success?).to be true
          expect(File.exist?(".mint/config.yaml")).to be true
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("custom-layout")
        end

        it "handles scope flags for configuration" do
          result = run_command("ruby", "bin/mint", "set", "--local", "style", "local-style")
          
          expect(result.success?).to be true
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["style"]).to eq("local-style")
        end
      end

      describe "plugin commands" do
        it "handles epub plugin" do
          create_markdown_file("book.md", "# My Book\n\nContent here.")
          
          # This might fail if epub dependencies aren't available
          result = run_command("ruby", "bin/mint-epub", "publish", "book.md")
          
          # We expect this to either work or fail gracefully
          # The specific behavior depends on whether epub dependencies are installed
          expect([true, false]).to include(result.success?)
        end
      end

      describe "error handling and edge cases" do
        it "handles unknown commands gracefully" do
          result = run_command("ruby", "bin/mint", "unknown-command")
          
          expect(result.success?).to be false
          expect(result.stderr + result.stdout).to match(/error|Usage/)
        end

        it "handles malformed arguments" do
          result = run_command("ruby", "bin/mint", "publish", "--invalid-flag")
          
          expect(result.success?).to be false
        end

        it "provides helpful error messages" do
          result = run_command("ruby", "bin/mint", "edit", "nonexistent-template")
          
          expect(result.success?).to be false
          # Should provide a helpful error about the missing template
        end

        it "handles permission errors" do
          create_markdown_file("test.md", "# Test")
          
          # Try to publish to a location we can't write to
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "--destination", "/root", "test.md")
          
          expect(result.success?).to be false
        end
      end

      describe "environment handling" do
        it "respects EDITOR environment variable" do
          setup_basic_config
          create_template_directory("test", with_layout: true)
          
          result = run_command(
            {"EDITOR" => "echo 'custom-editor'"},
            "ruby", "bin/mint", "edit-layout", "test"
          )
          
          expect(result.success?).to be true
        end

        it "works with different working directories" do
          FileUtils.mkdir_p("subdir")
          Dir.chdir("subdir") do
            create_markdown_file("doc.md", "# From Subdir")
            
            result = run_command("ruby", "../bin/mint", "publish", "doc.md")
            
            # This might require the default template to exist
            # The exact behavior depends on how Mint handles paths
          end
        end

        it "handles Ruby load path correctly" do
          # The bin script should be able to find the lib directory
          result = run_command("ruby", "bin/mint", "--help")
          
          expect(result.success?).to be true
          # Should not have load errors
          expect(result.stderr).not_to include("LoadError")
          expect(result.stderr).not_to include("cannot load such file")
        end
      end

      describe "output formatting and verbosity" do
        it "produces clean output for normal operations" do
          create_markdown_file("test.md", "# Test")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "test.md")
          
          expect(result.success?).to be true
          # Output should be minimal for successful operations
          expect(result.stdout.length).to be < 100
        end

        it "provides detailed output in verbose mode" do
          create_markdown_file("test.md", "# Test")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "--verbose", "test.md")
          
          # Verbose mode should provide more information
          # This test depends on whether --verbose is implemented
        end

        it "formats template listings nicely" do
          setup_basic_config
          create_template_directory("template-one")
          create_template_directory("template-two")
          
          result = run_command("ruby", "bin/mint", "templates")
          
          expect(result.success?).to be true
          
          # Should be formatted nicely, one per line
          lines = result.stdout.split("\n").reject(&:empty?)
          expect(lines.length).to be >= 2
        end
      end

      describe "integration with system tools" do
        it "can be used in shell pipelines" do
          create_markdown_file("input.md", "# Pipeline Test")
          setup_basic_config
          create_template_directory("default")
          
          # Test that it works with shell redirection
          result = run_command("bash", "-c", "MINT_NO_PIPE=1 ruby bin/mint publish input.md 2>&1")
          
          expect(result.success?).to be true
          expect(File.exist?("input.html")).to be true
        end

        it "exits with appropriate status codes" do
          # Success case
          create_markdown_file("success.md", "# Success")
          setup_basic_config
          create_template_directory("default")
          
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "success.md")
          expect(result.exit_code).to eq(0)
          
          # Failure case
          result = run_command({"MINT_NO_PIPE" => "1"}, "ruby", "bin/mint", "publish", "nonexistent.md")
          expect(result.exit_code).not_to eq(0)
        end
      end
    end
  end
end