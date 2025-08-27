require "spec_helper"

RSpec.describe "CLI Publishing Workflow" do
  describe "Mint::CommandLine.publish!" do
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          setup_basic_config
          create_template_directory("default")
          example.run
        end
      end

      describe "basic publishing" do
        it "publishes a single markdown file" do
          markdown_file = create_markdown_file("test.md", "# Hello World\n\nThis is a test.")
          
          expect {
            Mint::CommandLine.publish!([markdown_file], {})
          }.not_to raise_error
          
          verify_file_content("test.html") do |content|
            expect(content).to include("<h1>Hello World</h1>")
            expect(content).to include("<p>This is a test.</p>")
          end
        end

        it "publishes multiple markdown files" do
          file1 = create_markdown_file("doc1.md", "# Document 1")
          file2 = create_markdown_file("doc2.md", "# Document 2")
          
          expect {
            Mint::CommandLine.publish!([file1, file2], {})
          }.not_to raise_error
          
          verify_file_content("doc1.html") do |content|
            expect(content).to include("<h1>Document 1</h1>")
          end
          
          verify_file_content("doc2.html") do |content|
            expect(content).to include("<h1>Document 2</h1>")
          end
        end

        it "uses default template when none specified" do
          markdown_file = create_markdown_file("test.md", "# Test")
          
          Mint::CommandLine.publish!([markdown_file], {})
          
          verify_file_content("test.html") do |content|
            expect(content).to include("<!DOCTYPE html>")
            expect(content).to include("<html>")
            expect(content).to include("</html>")
          end
        end
      end

      describe "with custom options" do
        it "publishes with custom destination" do
          markdown_file = create_markdown_file("test.md", "# Test")
          FileUtils.mkdir_p("output")
          
          Mint::CommandLine.publish!([markdown_file], { destination: "output" })
          
          expect(File.exist?("output/test.html")).to be true
          expect(File.exist?("test.html")).to be false
        end

        it "publishes with custom root directory" do
          # Create a subdirectory structure
          FileUtils.mkdir_p("docs")
          Dir.chdir("docs") do
            create_markdown_file("readme.md", "# Documentation")
          end
          
          # Publish from parent directory with current directory as root
          Mint::CommandLine.publish!(["docs/readme.md"], { root: Dir.getwd })
          
          expect(File.exist?("docs/readme.html")).to be true
        end

        it "uses custom template" do
          create_template_directory("custom", with_layout: true, with_style: true)
          File.write(".mint/templates/custom/layout.erb", 
            "<html><body class='custom'><%= content %></body></html>")
          
          markdown_file = create_markdown_file("test.md", "# Test")
          
          Mint::CommandLine.publish!([markdown_file], { layout: "custom" })
          
          verify_file_content("test.html") do |content|
            expect(content).to include("class='custom'")
          end
        end

        it "applies custom style template" do
          create_template_directory("styled", with_layout: true, with_style: true)
          File.write(".mint/templates/styled/style.css", 
            "body { background: red; }")
          
          markdown_file = create_markdown_file("test.md", "# Test")
          
          Mint::CommandLine.publish!([markdown_file], { style: "styled" })
          
          # Check if style file was created and linked
          expect(File.exist?("test.html")).to be true
          # Style files are typically processed to a temp directory
        end
      end

      describe "recursive publishing" do
        it "discovers and publishes markdown files recursively" do
          # Create nested directory structure with markdown files
          FileUtils.mkdir_p("docs/section1")
          FileUtils.mkdir_p("docs/section2")
          
          create_markdown_file("docs/index.md", "# Main Documentation")
          create_markdown_file("docs/section1/intro.md", "# Introduction") 
          create_markdown_file("docs/section2/advanced.md", "# Advanced Topics")
          
          # Also create non-markdown files that should be ignored
          File.write("docs/config.yaml", "key: value")
          File.write("docs/section1/script.js", "console.log('test');")
          
          Mint::CommandLine.publish!(["docs"], { recursive: true })
          
          expect(File.exist?("docs/index.html")).to be true
          expect(File.exist?("docs/section1/intro.html")).to be true
          expect(File.exist?("docs/section2/advanced.html")).to be true
          
          # Non-markdown files should not be converted
          expect(File.exist?("docs/config.html")).to be false
          expect(File.exist?("docs/section1/script.html")).to be false
        end

        it "handles empty directories gracefully" do
          FileUtils.mkdir_p("empty/nested/dirs")
          
          expect {
            Mint::CommandLine.publish!(["empty"], { recursive: true })
          }.not_to raise_error
        end

        it "processes current directory when no files specified" do
          create_markdown_file("current.md", "# Current Directory")
          FileUtils.mkdir_p("sub")
          create_markdown_file("sub/nested.md", "# Nested File")
          
          Mint::CommandLine.publish!([], { recursive: true })
          
          expect(File.exist?("current.html")).to be true
          expect(File.exist?("sub/nested.html")).to be true
        end
      end

      describe "file discovery" do
        it "recognizes various markdown extensions" do
          # Create files with different markdown extensions
          extensions = %w[md markdown mkd]
          extensions.each_with_index do |ext, i|
            create_markdown_file("test#{i}.#{ext}", "# Test #{i}")
          end
          
          files = extensions.map.with_index {|ext, i| "test#{i}.#{ext}" }
          Mint::CommandLine.publish!(files, {})
          
          extensions.each_with_index do |ext, i|
            expect(File.exist?("test#{i}.html")).to be true
          end
        end

        it "processes files with complex content" do
          complex_content = <<~MARKDOWN
            # Main Title
            
            ## Subtitle
            
            This is a paragraph with **bold** and *italic* text.
            
            - List item 1
            - List item 2
            - List item 3
            
            ```ruby
            def hello
              puts "Hello, World!"
            end
            ```
            
            | Column 1 | Column 2 |
            |----------|----------|
            | Cell 1   | Cell 2   |
            | Cell 3   | Cell 4   |
            
            [Link to example](https://example.com)
          MARKDOWN
          
          create_markdown_file("complex.md", complex_content)
          
          Mint::CommandLine.publish!(["complex.md"], {})
          
          verify_file_content("complex.html") do |content|
            expect(content).to include("<h1>Main Title</h1>")
            expect(content).to include("<h2>Subtitle</h2>")
            expect(content).to include("<strong>bold</strong>")
            expect(content).to include("<em>italic</em>")
            expect(content).to include("<ul>")
            expect(content).to include("<code")
            expect(content).to include("href=\"https://example.com\"")
          end
        end
      end

      describe "error handling" do
        it "handles missing source files gracefully" do
          expect {
            Mint::CommandLine.publish!(["nonexistent.md"], {})
          }.to raise_error(Errno::ENOENT) # Should raise an error for missing file
        end

        it "handles permission errors" do
          # Create a file, then make directory read-only
          markdown_file = create_markdown_file("test.md", "# Test")
          
          # Try to publish to a non-writable location
          # This test might be platform-specific
          expect {
            Mint::CommandLine.publish!([markdown_file], { destination: "/root" })
          }.to raise_error(Errno::EROFS) # Should fail due to permissions
        end

        it "handles invalid templates gracefully" do
          markdown_file = create_markdown_file("test.md", "# Test")
          
          expect {
            Mint::CommandLine.publish!([markdown_file], { layout: "nonexistent" })
          }.to raise_error(Mint::TemplateNotFoundException)
        end
      end

      describe "output file naming" do
        it "preserves directory structure in output" do
          FileUtils.mkdir_p("input/subdir")
          create_markdown_file("input/subdir/doc.md", "# Nested Document")
          
          Mint::CommandLine.publish!(["input/subdir/doc.md"], {})
          
          expect(File.exist?("input/subdir/doc.html")).to be true
        end

        it "handles files with no extension" do
          File.write("README", "# Readme\n\nThis is a readme file.")
          
          # This might fail if README is not recognized as markdown
          # The behavior depends on how Mint determines file types
        end

        it "overwrites existing output files" do
          markdown_file = create_markdown_file("test.md", "# Version 1")
          File.write("test.html", "<html>Old content</html>")
          
          Mint::CommandLine.publish!([markdown_file], {})
          
          verify_file_content("test.html") do |content|
            expect(content).to include("Version 1")
            expect(content).not_to include("Old content")
          end
        end
      end

      describe "configuration integration" do
        it "respects configuration file settings" do
          # Create custom config
          config_content = {
            'layout' => 'custom',
            'style' => 'minimal',
            'destination' => 'build'
          }
          File.write(".mint/config.yaml", config_content.to_yaml)
          
          # Create the referenced templates
          create_template_directory("custom")
          create_template_directory("minimal")
          FileUtils.mkdir_p("build")
          
          markdown_file = create_markdown_file("test.md", "# Test")
          
          Mint::CommandLine.publish!([markdown_file], {})
          
          expect(File.exist?("build/test.html")).to be true
        end

        it "allows command-line options to override config" do
          # Set config with default destination
          config_content = { 'destination' => 'config_output' }
          File.write(".mint/config.yaml", config_content.to_yaml)
          
          FileUtils.mkdir_p("cli_output")
          markdown_file = create_markdown_file("test.md", "# Test")
          
          # Override with CLI option
          Mint::CommandLine.publish!([markdown_file], { destination: "cli_output" })
          
          expect(File.exist?("cli_output/test.html")).to be true
          expect(File.exist?("config_output/test.html")).to be false
        end
      end

      describe "multi-file processing" do
        it "processes multiple files efficiently" do
          files = []
          10.times do |i|
            files << create_markdown_file("doc#{i}.md", "# Document #{i}")
          end
          
          start_time = Time.now
          Mint::CommandLine.publish!(files, {})
          end_time = Time.now
          
          # All files should be processed
          10.times do |i|
            expect(File.exist?("doc#{i}.html")).to be true
          end
          
          # Should complete in reasonable time (this is somewhat arbitrary)
          expect(end_time - start_time).to be < 5.0
        end

        it "passes file list to templates for navigation" do
          # This tests the all_files feature for multi-file processing
          files = []
          3.times do |i|
            files << create_markdown_file("page#{i}.md", "# Page #{i}")
          end
          
          # Create a template that uses the all_files variable
          nav_template = <<~ERB
            <html>
            <body>
              <nav>
                <% if files && files.any? %>
                  <% files.each do |file| %>
                    <a href="<%= file[:html_path] %>"><%= file[:title] %></a>
                  <% end %>
                <% end %>
              </nav>
              <%= content %>
            </body>
            </html>
          ERB
          
          FileUtils.mkdir_p(".mint/templates/nav")
          File.write(".mint/templates/nav/layout.erb", nav_template)
          
          Mint::CommandLine.publish!(files, { layout: "nav" })
          
          # Check that navigation was included
          verify_file_content("page0.html") do |content|
            expect(content).to include("<nav>")
            expect(content).to include("Page 1")
            expect(content).to include("Page 2")
          end
        end
      end
    end
  end
end