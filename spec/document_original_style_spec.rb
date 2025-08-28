require "spec_helper"
require "mint/document"
require "tempfile"
require "pathname"

describe "Document with original style mode" do
  let(:temp_dir) { Dir.mktmpdir }
  let(:markdown_content) { "# Test Document\n\nThis is a test." }
  
  after do
    FileUtils.rm_rf(temp_dir)
  end

  def create_custom_template(template_name, css_content, imports: [])
    # Create a proper Mint template structure
    template_dir = File.join(temp_dir, ".mint", "templates", template_name)
    FileUtils.mkdir_p(template_dir)
    
    # Create style.css with imports
    style_css = File.join(template_dir, "style.css")
    File.write(style_css, css_content)
    
    # Create imported files
    imports.each do |import_file, import_content|
      import_path = File.join(template_dir, import_file)
      FileUtils.mkdir_p(File.dirname(import_path))
      File.write(import_path, import_content)
    end
    
    # Create a basic layout
    layout_erb = File.join(template_dir, "layout.erb")
    File.write(layout_erb, <<~LAYOUT)
      <!DOCTYPE html>
      <html>
        <head>
          <%= stylesheet_tag %>
        </head>
        <body>
          <%= content %>
        </body>
      </html>
    LAYOUT
    
    template_name
  end

  context "when using original style mode" do
    it "generates link tags for built-in templates" do
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: "default"
        )
        
        tags = document.original_stylesheet_tags
        expect(tags).to match(/config\/templates\/default\/style\.css/)
        expect(tags).to match(/config\/templates\/base\/style\.css/)
        expect(tags).to include('<link rel="stylesheet"')
      end
    end

    it "generates link tags for custom templates with imports" do
      template_name = create_custom_template(
        "custom", 
        '@import "reset.css"; body { margin: 0; }',
        imports: [["reset.css", "* { box-sizing: border-box; }"]]
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: template_name
        )
        
        tags = document.original_stylesheet_tags
        expect(tags).to include('.mint/templates/custom/style.css')
        expect(tags).to include('.mint/templates/custom/reset.css')
      end
    end

    it "handles templates with no imports" do
      template_name = create_custom_template(
        "simple", 
        "body { color: black; font-size: 16px; }"
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: template_name
        )
        
        tags = document.original_stylesheet_tags
        expect(tags).to eq('<link rel="stylesheet" href=".mint/templates/simple/style.css">')
      end
    end

    it "integrates properly with stylesheet_tag method" do
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: "nord"
        )
        
        stylesheet_tag = document.stylesheet_tag
        expect(stylesheet_tag).to include('<link rel="stylesheet"')
        expect(stylesheet_tag).to match(/config\/templates\/nord\/style\.css/)
        expect(stylesheet_tag).not_to include('<style>')
      end
    end

    it "returns empty string when style is not CSS" do
      # Create a template with SCSS (not CSS)
      template_dir = File.join(temp_dir, ".mint", "templates", "scss_template")
      FileUtils.mkdir_p(template_dir)
      
      # Create style.scss instead of style.css
      File.write(File.join(template_dir, "style.scss"), '$color: blue; body { color: $color; }')
      File.write(File.join(template_dir, "layout.erb"), "<%= stylesheet_tag %>")
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: "scss_template"
        )
        
        # Should return empty because it's not a .css file
        expect(document.original_stylesheet_tags).to eq("")
      end
    end

    it "handles nested import paths correctly" do
      template_name = create_custom_template(
        "nested",
        '@import "components/buttons.css"; body { margin: 0; }',
        imports: [["components/buttons.css", ".btn { padding: 10px; }"]]
      )
      
      markdown_file = File.join(temp_dir, "test.md")
      File.write(markdown_file, markdown_content)
      
      Dir.chdir(temp_dir) do
        document = Mint::Document.new(
          File.basename(markdown_file),
          style_mode: :original,
          template: template_name
        )
        
        tags = document.original_stylesheet_tags
        expect(tags).to include('.mint/templates/nested/style.css')
        expect(tags).to include('.mint/templates/nested/components/buttons.css')
      end
    end
  end
end