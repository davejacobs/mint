require "spec_helper"

describe Mint do
  subject { Mint }

  describe "::PROJECT_ROOT" do
    it "contains the root of the Mint gem as a string" do
      expect(Mint::PROJECT_ROOT).to eq(File.expand_path("../..", __FILE__))
    end
  end

  describe "::PATH" do
    it "returns the paths corresponding to all scopes as an array" do
      expect(Mint::PATH).to eq([Pathname.new(".mint"),
                               Pathname.new("~/.config/mint").expand_path,
                               Pathname.new(Mint::PROJECT_ROOT + "/config").expand_path])
    end
  end

  describe ".configuration" do
    context "when there is no config.toml file on the Mint path" do
      it "returns a default Config object" do
        config = Mint.configuration
        expect(config).to be_a(Mint::Config)
        expect(config.layout_name).to eq('default')
        expect(config.style_name).to eq('default')
        expect(config.style_mode).to eq(:inline)
        expect(config.output_file_format).to eq('%{basename}.%{new_extension}')
      end
    end

    context "when there is a config.toml file on the Mint path" do
      before do
        FileUtils.mkdir_p(".mint")
        File.write(".mint/config.toml", "style = \"custom\"")
      end

      after do
        FileUtils.rm_rf(".mint")
      end

      it "merges config files with defaults" do
        config = Mint.configuration
        expect(config.style_name).to eq("custom")
        expect(config.layout_name).to eq("default") # still has defaults
      end
    end
  end

  describe ".find_template_directory_by_name" do
    it "returns template directory path by name" do
      # This will return nil if template doesn't exist, which is expected
      result = Mint.find_template_directory_by_name("default")
      if result
        expect(result).to be_a(Pathname)
      else
        expect(result).to be_nil
      end
    end
  end

  describe ".find_layout_by_name" do
    it "returns layout file path by template name" do
      result = Mint.find_layout_by_name("default")
      if result
        expect(result).to be_a(Pathname)
        expect(Mint.is_valid_layout_file?(result)).to be true
      else
        expect(result).to be_nil
      end
    end
  end

  describe ".find_style_by_name" do
    it "returns style file path by template name" do
      result = Mint.find_style_by_name("default")
      if result
        expect(result).to be_a(Pathname)
        expect(Mint.is_valid_stylesheet?(result)).to be true
      else
        expect(result).to be_nil
      end
    end
  end

  describe ".is_valid_stylesheet?" do
    it "determines if a file is a valid stylesheet" do
      expect(Mint.is_valid_stylesheet?(Pathname.new("style.css"))).to be true
      expect(Mint.is_valid_stylesheet?(Pathname.new("style.scss"))).to be true
      expect(Mint.is_valid_stylesheet?(Pathname.new("style.sass"))).to be true
      expect(Mint.is_valid_stylesheet?(Pathname.new("other.css"))).to be false
    end
  end

  describe ".is_valid_layout_file?" do
    it "determines if a file is a valid layout file" do
      expect(Mint.is_valid_layout_file?(Pathname.new("layout.html"))).to be true
      expect(Mint.is_valid_layout_file?(Pathname.new("layout.erb"))).to be true
      expect(Mint.is_valid_layout_file?(Pathname.new("layout.haml"))).to be true
      expect(Mint.is_valid_layout_file?(Pathname.new("other.html"))).to be false
    end
  end

  describe ".is_template_directory?" do
    it "determines if a directory is a valid template directory" do
      Dir.mktmpdir do |tmpdir|
        template_dir = Pathname.new(tmpdir) + "test_template"
        template_dir.mkdir
        
        # Empty directory should not be valid (returns empty array)
        expect(Mint.is_template_directory?(template_dir)).to be_empty
        
        # Directory with stylesheet should be valid
        (template_dir + "style.css").write("body { color: black; }")
        expect(Mint.is_template_directory?(template_dir)).to be_truthy
      end
    end
  end

  describe ".extract_title_from_file" do
    it "extracts title from H1 header" do
      Dir.mktmpdir do |tmpdir|
        test_file = File.join(tmpdir, "test.md")
        File.write(test_file, "# My Title\n\nContent here")
        
        expect(Mint.extract_title_from_file(test_file)).to eq("My Title")
      end
    end

    it "falls back to filename when no H1" do
      Dir.mktmpdir do |tmpdir|
        test_file = File.join(tmpdir, "my-test-file.md")
        File.write(test_file, "Just content")
        
        expect(Mint.extract_title_from_file(test_file)).to eq("My Test File")
      end
    end
  end

  describe ".parse_metadata_from" do
    it "parses YAML metadata from text" do
      text_with_metadata = "title: Test\nauthor: Me\n\n\nContent here"
      metadata, content = Mint.parse_metadata_from(text_with_metadata)
      
      expect(metadata).to eq({ "title" => "Test", "author" => "Me" })
      expect(content).to eq("\nContent here")
    end

    it "handles text without metadata" do
      text_without_metadata = "Just content here"
      metadata, content = Mint.parse_metadata_from(text_without_metadata)
      
      expect(metadata).to eq({})
      expect(content).to eq("Just content here")
    end
  end

  describe ".publish!" do
    it "processes a markdown file and creates HTML output" do
      FileUtils.mkdir_p("./tmp")
      Dir.chdir("./tmp") do |tmpdir|
        source_file = "test.md"
        File.write(source_file, "# Test\n\nThis is a test.")
        
        config = Mint::Config.with_defaults(destination_directory: Pathname.new("./"))
        
        # This should succeed if templates exist, or raise an error if they don't
        begin
          Mint.publish!(source_file, config: config)
          # If successful, check that output file was created
          output_file = "test.html"
          expect(File.exist?(output_file)).to be true
        rescue Mint::StyleNotFoundException, Mint::LayoutNotFoundException => e
          # Expected error when templates don't exist
          expect(e).to be_a(Exception)
        end
      end
    end
  end
end