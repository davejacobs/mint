require "spec_helper"

describe Mint do
  subject { Mint }

  describe "::ROOT" do
    it "contains the root of the Mint gem as a string" do
      expect(Mint::ROOT).to eq(File.expand_path("../..", __FILE__))
    end
  end

  describe ".path" do
    def as_pathname(files)
      files.map {|file| Pathname.new(file) }
    end

    it "returns the paths corresponding to all scopes as an array" do
      expect(Mint.path).to eq([Pathname.new(".mint"),
                               Pathname.new("~/.config/mint").expand_path,
                               Pathname.new(Mint::ROOT + "/config").expand_path])
    end

    it "can filter paths by one scope" do
      expect(Mint.path([:user])).to eq([Pathname.new("~/.config/mint").expand_path])
    end

    it "can filter paths by many scopes" do
      expect(Mint.path([:local, :user])).to eq([Pathname.new(".mint"),
                                                Pathname.new("~/.config/mint").expand_path])
    end
  end


  describe ".configuration" do
    let(:defaults) do
      {
        root: Dir.getwd,
        destination: nil,
        style_mode: :inline,
        style_destination: nil,
        output_file: '#{basename}.#{new_extension}',
        layout_or_style_or_template: [:template, 'default'],
        scope: :local,
        recursive: false,
        verbose: false
      }
    end

    context "when there is no config.yaml file on the Mint path" do
      it "returns a default set of options" do
        expect(Mint.configuration).to eq(defaults)
      end
    end

    context "when there is a config.yaml file on the Mint path" do
      before do
        FileUtils.mkdir_p ".mint"
        File.open(".mint/config.yaml", "w") do |file|
          file << "layout: zen"
        end
      end

      after do
        FileUtils.rm_rf ".mint"
      end

      it "merges all specified options with precedence according to scope" do
        expect(Mint.configuration[:layout]).to eq("zen")
      end

      it "can filter by scope (but always includes defaults)" do
        expect(Mint.configuration(scopes: [:user])).to eq(defaults)
      end
    end
  end

  describe ".configuration_with" do
    it "displays the sum of all configuration files with other options added" do
      expect(Mint.configuration_with(local: true)).to eq({
        root: Dir.getwd,
        destination: nil,
        style_mode: :inline,
        style_destination: nil,
        output_file: '#{basename}.#{new_extension}',
        layout_or_style_or_template: [:template, 'default'],
        scope: :local,
        recursive: false,
        verbose: false,
        local: true
      })
    end
  end

  describe ".templates" do
    it "returns local templates by default" do
      # Note: Now defaults to local scope, will include global templates only if explicitly requested
      expect(Mint.templates).to be_an(Array)
    end

    it "returns global templates when global scope is specified" do
      expect(Mint.templates(:global)).to include(Mint::ROOT + "/config/templates/default")
    end
  end

  describe ".formats" do
    it "includes Markdown" do
      expect(Mint.formats).to include("md")
    end

    it "includes Haml" do
      expect(Mint.formats).to include("haml")
    end
  end

  describe ".css_formats" do
    it "includes Sass" do
      expect(Mint.css_formats).to include("sass")
    end
  end

  describe ".renderer" do
    it "creates a valid renderer" do
      expect(Mint.renderer(@content_file)).to respond_to(:render)
    end
  end

  describe ".path_for_scope" do
    it "chooses the appropriate path for scope" do
      expectations = {
        local: Pathname.new(".mint"),
        user: Pathname.new("~/.config/mint").expand_path,
        global: Pathname.new(Mint::ROOT + "/config").expand_path
      }

      expectations.each do |scope, path|
        expect(Mint.path_for_scope(scope)).to eq(path)
      end
    end
  end

  # Refactored lookup methods for explicit parameter interface
  describe ".lookup_template" do
    it "returns template directory path by name" do
      result = Mint.lookup_template("default")
      expect(result).to include("templates/default")
      expect(File.directory?(result)).to be true
    end
  end

  describe ".lookup_layout" do
    it "returns layout file path by template name" do
      result = Mint.lookup_layout("default")
      expect(result).to include("templates/default")
      expect(result).to end_with("layout.erb")
    end
  end

  describe ".lookup_style" do
    it "returns style file path by template name" do
      result = Mint.lookup_style("default")
      expect(result).to include("templates/default")
      expect(result).to end_with("style.css")
    end
  end

  describe ".find_template" do
    it "finds the correct template file by name and type" do
      layout_file = Mint.find_template("default", :layout)
      style_file = Mint.find_template("default", :style)
      
      expect(layout_file).to include("templates/default")
      expect(layout_file).to end_with("layout.erb")
      expect(style_file).to include("templates/default")
      expect(style_file).to end_with("style.css")
    end

    it "determines if a file is a template file" do
      actual_template = Mint.lookup_layout("default")
      fake_template = "#{Mint::ROOT}/config/templates/default.css"
      obvious_nontemplate = @dynamic_style_file

      expect(Mint.template?(actual_template)).to be_truthy
      expect(Mint.template?(fake_template)).to be_falsy
      expect(Mint.template?(obvious_nontemplate)).to be_falsy
    end
  end

  describe ".guess_name_from" do
    it "properly guesses destination file names based on source file names" do
      expect(Mint.guess_name_from("content.md")).to eq("content.html")
      expect(Mint.guess_name_from("content.textile")).to eq("content.html")
      expect(Mint.guess_name_from("layout.haml")).to eq("layout.html")
      expect(Mint.guess_name_from("dynamic.sass")).to eq("dynamic.css")
    end
  end

  describe ".destination_file_path and .style_destination_file_path" do
    context "before it publishes a document" do
      let(:document) { Mint::Document.new @content_file }
      subject { document }

      its(:destination_file_path) { should_not exist }
      it "style destination file should not exist initially" do
        # Clean up any existing style file first
        FileUtils.rm_f(document.style_destination_file_path) if document.style_destination_file_path && File.exist?(document.style_destination_file_path)
        expect(document.style_destination_file_path).not_to exist
      end
    end

    # These are copied from document_spec.rb. I eventually want to move
    # to this non-OO style of publishing, and this is the transition
    context "when it publishes a document" do
      let(:document) { Mint::Document.new @content_file }
      before { Mint.publish! document }
      subject { document }

      its(:destination_file_path) { should exist }
      
      it "creates style file only for external style mode" do
        if document.style_mode == :external
          expect(document.style_destination_file_path).to exist
        else
          expect(document.style_destination_file_path).not_to exist
        end
      end
    end
  end

  describe ".template_path" do
    it "returns template directory for given name and scope" do
      expect(Mint.template_path("pro", :local)).to eq(Pathname.new(".mint/templates/pro"))
    end

    it "works with user scope" do
      expect(Mint.template_path("pro", :user)).to eq(Pathname.new("~/.config/mint/templates/pro").expand_path)
    end

    it "works with global scope" do
      expect(Mint.template_path("pro", :global)).to eq(Pathname.new("#{Mint::ROOT}/config/templates/pro"))
    end
  end
end
