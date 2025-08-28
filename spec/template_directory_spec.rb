require "spec_helper"
require "mint"
require "tempfile"

describe "Template directory support" do
  let(:temp_dir) { Dir.mktmpdir }
  
  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_template_directory(name, layout_content: nil, style_content: nil, layout_ext: "erb", style_ext: "css")
    template_dir = File.join(temp_dir, name)
    FileUtils.mkdir_p(template_dir)
    
    if layout_content
      File.write(File.join(template_dir, "layout.#{layout_ext}"), layout_content)
    end
    
    if style_content
      File.write(File.join(template_dir, "style.#{style_ext}"), style_content)
    end
    
    template_dir
  end

  describe "Mint.lookup_layout" do
    it "finds layout in directory path" do
      template_dir = create_template_directory("test", 
        layout_content: "<html><body><%= content %></body></html>"
      )
      
      layout_file = Mint.lookup_layout(template_dir)
      expect(layout_file).to eq(File.join(template_dir, "layout.erb"))
      expect(File.exist?(layout_file)).to be true
    end

    it "works with different layout extensions" do
      template_dir = create_template_directory("haml_test", 
        layout_content: "%html\n  %body= content",
        layout_ext: "haml"
      )
      
      layout_file = Mint.lookup_layout(template_dir)
      expect(layout_file).to eq(File.join(template_dir, "layout.haml"))
    end

    it "raises error when no layout file found in directory" do
      template_dir = create_template_directory("no_layout")
      
      expect {
        Mint.lookup_layout(template_dir)
      }.to raise_error(Mint::TemplateNotFoundException, /layout/)
    end

    it "still works with template names (backward compatibility)" do
      # This should still work with built-in templates
      layout_file = Mint.lookup_layout("default")
      expect(layout_file).to match(/config\/templates\/default\/layout\.erb/)
    end
  end

  describe "Mint.lookup_style" do
    it "finds style in directory path" do
      template_dir = create_template_directory("test", 
        style_content: "body { margin: 0; }"
      )
      
      style_file = Mint.lookup_style(template_dir)
      expect(style_file).to eq(File.join(template_dir, "style.css"))
      expect(File.exist?(style_file)).to be true
    end

    it "works with different style extensions" do
      template_dir = create_template_directory("scss_test", 
        style_content: "$color: blue;\nbody { color: $color; }",
        style_ext: "scss"
      )
      
      style_file = Mint.lookup_style(template_dir)
      expect(style_file).to eq(File.join(template_dir, "style.scss"))
    end

    it "raises error when no style file found in directory" do
      template_dir = create_template_directory("no_style")
      
      expect {
        Mint.lookup_style(template_dir)
      }.to raise_error(Mint::TemplateNotFoundException, /style/)
    end

    it "still works with template names (backward compatibility)" do
      # This should still work with built-in templates
      style_file = Mint.lookup_style("default")
      expect(style_file).to match(/config\/templates\/default\/style\.css/)
    end
  end

  describe "Document integration" do
    it "works with template directory paths" do
      template_dir = create_template_directory("complete",
        layout_content: "<!DOCTYPE html><html><body><%= content %></body></html>",
        style_content: "body { font-family: Arial; }"
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# Test Document\n\nContent here.")
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          template: template_dir
        )
        
        expect(document.layout.source).to eq(File.join(template_dir, "layout.erb"))
        expect(document.style.source).to eq(File.join(template_dir, "style.css"))
      end
    end

    it "works with relative directory paths" do
      template_dir = create_template_directory("relative_test",
        layout_content: "<%= content %>",
        style_content: "body { color: red; }"
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# Test")
      
      Dir.chdir(temp_dir) do
        relative_template_path = File.basename(template_dir)
        
        document = Mint::Document.new(
          File.basename(markdown_file),
          template: relative_template_path
        )
        
        expect(document.layout.source).to end_with("layout.erb")
        expect(document.style.source).to end_with("style.css")
      end
    end
  end

  describe "Command line integration" do
    it "publishes with directory template path" do
      template_dir = create_template_directory("cli_test",
        layout_content: "<!DOCTYPE html><html><head><%= stylesheet_tag %></head><body><%= content %></body></html>",
        style_content: "body { background: #f0f0f0; }"
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# CLI Test\n\nThis is a test.")
      
      Dir.chdir(temp_dir) do
        Mint::CommandLine.publish!(
          [File.basename(markdown_file)],
          template: template_dir
        )
        
        output_file = markdown_file.sub('.md', '.html')
        expect(File.exist?(output_file)).to be true
        
        content = File.read(output_file)
        expect(content).to include('<h1>CLI Test</h1>')
        expect(content).to include('This is a test')
        expect(content).to include('background: #f0f0f0')
      end
    end

    it "works with original style mode and directory templates" do
      template_dir = create_template_directory("original_test",
        layout_content: "<!DOCTYPE html><html><head><%= stylesheet_tag %></head><body><%= content %></body></html>",
        style_content: '@import "reset.css"; body { color: green; }'
      )
      
      # Add imported file
      File.write(File.join(template_dir, "reset.css"), "* { margin: 0; }")
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, "# Original Mode Test")
      
      Dir.chdir(temp_dir) do
        Mint::CommandLine.publish!(
          [File.basename(markdown_file)],
          template: template_dir,
          style_mode: :original
        )
        
        output_file = markdown_file.sub('.md', '.html')
        expect(File.exist?(output_file)).to be true
        
        content = File.read(output_file)
        expect(content).to include('<link rel="stylesheet"')
        expect(content).to include('style.css')
        expect(content).to include('reset.css')
        expect(content).not_to include('<style>')
      end
    end
  end
end