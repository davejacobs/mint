require "spec_helper"
require "mint/css_parser"
require "tempfile"
require "pathname"

describe Mint::CssParser do
  describe ".extract_imports" do
    it "extracts @import statements with double quotes" do
      css = '@import "reset.css"; body { margin: 0; }'
      imports = Mint::CssParser.extract_imports(css)
      expect(imports).to eq(["reset.css"])
    end

    it "extracts @import statements with single quotes" do
      css = "@import 'normalize.css'; .class { color: red; }"
      imports = Mint::CssParser.extract_imports(css)
      expect(imports).to eq(["normalize.css"])
    end

    it "extracts @import url() statements" do
      css = '@import url("fonts.css"); @import url(\'colors.css\');'
      imports = Mint::CssParser.extract_imports(css)
      expect(imports).to eq(["fonts.css", "colors.css"])
    end

    it "extracts multiple @import statements" do
      css = <<~CSS
        @import "reset.css";
        @import 'normalize.css';
        @import url("fonts.css");
        body { margin: 0; }
      CSS
      imports = Mint::CssParser.extract_imports(css)
      expect(imports).to eq(["reset.css", "normalize.css", "fonts.css"])
    end

    it "returns empty array when no imports found" do
      css = "body { margin: 0; color: blue; }"
      imports = Mint::CssParser.extract_imports(css)
      expect(imports).to eq([])
    end
  end

  describe ".resolve_css_files" do
    let(:temp_dir) { Dir.mktmpdir }
    
    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "resolves main CSS file path relative to HTML output" do
      # Create directory structure:
      # temp_dir/
      #   css/
      #     main.css
      #   output/
      #     index.html (output file)
      
      css_dir = File.join(temp_dir, "css")
      output_dir = File.join(temp_dir, "output")
      FileUtils.mkdir_p([css_dir, output_dir])
      
      main_css = File.join(css_dir, "main.css")
      html_output = File.join(output_dir, "index.html")
      
      File.write(main_css, "body { margin: 0; }")
      
      css_files = Mint::CssParser.resolve_css_files(main_css, html_output)
      expect(css_files).to eq(["../css/main.css"])
    end

    it "resolves main CSS and imported files" do
      # Create directory structure:
      # temp_dir/
      #   css/
      #     main.css (imports reset.css)
      #     reset.css
      #   output/
      #     index.html
      
      css_dir = File.join(temp_dir, "css")
      output_dir = File.join(temp_dir, "output")
      FileUtils.mkdir_p([css_dir, output_dir])
      
      main_css = File.join(css_dir, "main.css")
      reset_css = File.join(css_dir, "reset.css")
      html_output = File.join(output_dir, "index.html")
      
      File.write(main_css, '@import "reset.css"; body { margin: 0; }')
      File.write(reset_css, "* { box-sizing: border-box; }")
      
      css_files = Mint::CssParser.resolve_css_files(main_css, html_output)
      expect(css_files).to eq(["../css/main.css", "../css/reset.css"])
    end

    it "ignores non-existent imported files" do
      css_dir = File.join(temp_dir, "css")
      output_dir = File.join(temp_dir, "output")
      FileUtils.mkdir_p([css_dir, output_dir])
      
      main_css = File.join(css_dir, "main.css")
      html_output = File.join(output_dir, "index.html")
      
      File.write(main_css, '@import "nonexistent.css"; body { margin: 0; }')
      
      css_files = Mint::CssParser.resolve_css_files(main_css, html_output)
      expect(css_files).to eq(["../css/main.css"])
    end

    it "only processes .css files" do
      scss_dir = File.join(temp_dir, "scss")
      output_dir = File.join(temp_dir, "output")
      FileUtils.mkdir_p([scss_dir, output_dir])
      
      main_scss = File.join(scss_dir, "main.scss")
      html_output = File.join(output_dir, "index.html")
      
      File.write(main_scss, '@import "reset"; body { margin: 0; }')
      
      css_files = Mint::CssParser.resolve_css_files(main_scss, html_output)
      expect(css_files).to eq(["../scss/main.scss"])
    end
  end

  describe ".generate_link_tags" do
    it "generates HTML link tags for CSS files" do
      css_paths = ["../css/main.css", "../css/reset.css"]
      
      html = Mint::CssParser.generate_link_tags(css_paths)
      
      expected = <<~HTML.strip
        <link rel="stylesheet" href="../css/main.css">
            <link rel="stylesheet" href="../css/reset.css">
      HTML
      
      expect(html).to eq(expected)
    end

    it "handles empty array" do
      html = Mint::CssParser.generate_link_tags([])
      expect(html).to eq("")
    end

    it "handles single CSS file" do
      html = Mint::CssParser.generate_link_tags(["styles.css"])
      expect(html).to eq('<link rel="stylesheet" href="styles.css">')
    end
  end
end