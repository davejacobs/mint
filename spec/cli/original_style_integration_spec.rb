require "spec_helper"
require "mint/command_line"
require "tempfile"

describe "Original style mode integration" do
  let(:temp_dir) { Dir.mktmpdir }
  
  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_test_files
    # Create directory structure
    css_dir = File.join(temp_dir, "styles")
    FileUtils.mkdir_p(css_dir)
    
    # Create CSS files with imports
    main_css = File.join(css_dir, "main.css")
    reset_css = File.join(css_dir, "reset.css")
    
    File.write(main_css, <<~CSS)
      @import "reset.css";
      body {
        font-family: Arial, sans-serif;
        color: #333;
      }
    CSS
    
    File.write(reset_css, <<~CSS)
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }
    CSS
    
    # Create markdown file
    markdown_file = File.join(temp_dir, "test.md")
    File.write(markdown_file, "# Test Document\n\nContent here.")
    
    { main_css: main_css, markdown: markdown_file }
  end

  context "with --style-mode original" do
    it "works with built-in templates in original mode" do
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# Built-in Template Test\n\nContent.")
      
      Dir.chdir(temp_dir) do
        Mint::CommandLine.publish!(
          [File.basename(markdown_file)],
          style_mode: :original,
          template: "default"
        )
        
        output_file = markdown_file.sub('.md', '.html')
        expect(File.exist?(output_file)).to be true
        
        content = File.read(output_file)
        # Should have links to the actual template CSS files
        expect(content).to match(/<link rel="stylesheet" href="[^"]*\/config\/templates\/default\/style\.css">/)
        expect(content).to match(/<link rel="stylesheet" href="[^"]*\/config\/templates\/base\/style\.css">/)
      end
    end

    it "correctly outputs original style mode with different templates" do
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# Nord Template Test\n\nTesting nord template.")
      
      Dir.chdir(temp_dir) do
        Mint::CommandLine.publish!(
          [File.basename(markdown_file)],
          style_mode: :original,
          template: "nord"
        )
        
        output_file = markdown_file.sub('.md', '.html')
        expect(File.exist?(output_file)).to be true
        
        content = File.read(output_file)
        # Should have links to the actual template CSS files
        expect(content).to match(/<link rel="stylesheet" href="[^"]*\/config\/templates\/nord\/style\.css">/)
        # Nord template imports base/style.css, so it should include base/style.css
        expect(content).to match(/<link rel="stylesheet" href="[^"]*\/config\/templates\/base\/style\.css">/)
        expect(content).not_to include('<style>')
      end
    end
  end
end