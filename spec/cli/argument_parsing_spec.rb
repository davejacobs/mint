require "spec_helper"

RSpec.describe "CLI Argument Parsing" do
  describe "Mint::Commandline.parse!" do
    context "with no arguments" do
      it "returns default config and no files" do
        config, files, help = Mint::Commandline.parse!([])

        expect(config.working_directory).to be_a(Pathname)
        expect(config.layout_name).to eq('default')
        expect(config.style_name).to eq('default')
        expect(files).to eq([])
        expect(help).to include("Usage: mint")
      end
    end

    context "with template options" do
      it "parses --template option" do
        config, files, help = Mint::Commandline.parse!(["--template", "basic", "file.md"])

        expect(config.layout_name).to eq("basic")
        expect(config.style_name).to eq("basic")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses --layout option" do
        config, files, help = Mint::Commandline.parse!(["--layout", "custom", "file.md"])
                expect(config.layout_name).to eq("custom")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses -l option for layout" do
        config, files, help = Mint::Commandline.parse!(["-l", "custom", "file.md"])
                expect(config.layout_name).to eq("custom")
      end

      it "parses --style option" do
        config, files, help = Mint::Commandline.parse!(["--style", "minimal", "file.md"])
                expect(config.style_name).to eq("minimal")
      end

      it "handles short flags for templates" do
        config, files, help = Mint::Commandline.parse!(["-t", "pro", "file.md"])
                expect(config.layout_name).to eq("pro")
        expect(config.style_name).to eq("pro")
      end
    end

    context "with path options" do
      it "parses --working-dir option" do
        config, files, help = Mint::Commandline.parse!(["--working-dir", "/custom/path", "file.md"])
        expect(config.working_directory).to eq(Pathname.new("/custom/path"))
      end

      it "parses --destination option" do
        config, files, help = Mint::Commandline.parse!(["--destination", "output", "file.md"])
        expect(config.destination_directory).to eq(Pathname.new("output"))
      end

      it "parses --style-destination option" do
        config, files, help = Mint::Commandline.parse!(["--style-destination", "css", "file.md"])
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end

    context "with output options" do
      it "parses --output-file option" do
        config, files, help = Mint::Commandline.parse!(["--output-file", "%{name}_custom.%{ext}", "file.md"])
        expect(config.output_file_format).to eq("%{name}_custom.%{ext}")
      end

      it "has default output file format" do
        config, files, help = Mint::Commandline.parse!(["file.md"])

        expect(config.output_file_format).to eq("%{name}.%{ext}")
      end

      it "parses --output-file - for stdout" do
        config, files, help = Mint::Commandline.parse!(["--output-file", "-", "file.md"])

        expect(config.stdout_mode).to be true
      end
    end

    context "with style mode options" do
      it "parses --style-mode inline" do
        config, files, help = Mint::Commandline.parse!(["--style-mode", "inline", "file.md"])
        expect(config.style_mode).to eq(:inline)
      end

      it "parses --style-mode external" do
        config, files, help = Mint::Commandline.parse!(["--style-mode", "external", "file.md"])
        expect(config.style_mode).to eq(:external)
      end
    end

    context "with file handling" do
      it "processes multiple files" do
        config, files, help = Mint::Commandline.parse!(["file1.md", "file2.md", "file3.md"])
        expect(files.length).to eq(3)
        expect(files.map(&:basename).map(&:to_s)).to eq(["file1.md", "file2.md", "file3.md"])
      end
    end

    context "style destination behavior" do
      it "automatically sets external mode when style-destination is used" do
        config, files, help = Mint::Commandline.parse!(["--style-destination", "css", "file.md"])
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end

    context "boolean flags" do
      it "parses --preserve-structure flag" do
        config, files, help = Mint::Commandline.parse!(["--preserve-structure", "file.md"])
        expect(config.preserve_structure).to be true
      end

      it "parses --navigation flag" do
        config, files, help = Mint::Commandline.parse!(["--navigation", "file.md"])
        expect(config.navigation).to be true
      end

      it "parses --insert-title-heading flag" do
        config, files, help = Mint::Commandline.parse!(["--insert-title-heading", "file.md"])
        expect(config.insert_title_heading).to be true
      end

      it "parses --autodrop flag" do
        config, files, help = Mint::Commandline.parse!(["--autodrop", "file.md"])
        expect(config.autodrop).to be true
      end
    end

    context "negative boolean flags" do
      it "parses --no-preserve-structure flag" do
        config, files, help = Mint::Commandline.parse!(["--no-preserve-structure", "file.md"])
        expect(config.preserve_structure).to be false
      end

      it "parses --no-navigation flag" do
        config, files, help = Mint::Commandline.parse!(["--no-navigation", "file.md"])
        expect(config.navigation).to be false
      end

      it "parses --no-insert-title-heading flag" do
        config, files, help = Mint::Commandline.parse!(["--no-insert-title-heading", "file.md"])
        expect(config.insert_title_heading).to be false
      end

      it "parses --no-autodrop flag" do
        config, files, help = Mint::Commandline.parse!(["--no-autodrop", "file.md"])

        expect(config.autodrop).to be false
      end
    end

    context "stdout mode validation" do
      it "allows --output-file - with single file" do
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "file.md"])
        }.not_to raise_error
      end

      it "allows --output-file - with STDIN" do
        allow($stdin).to receive(:read).and_return("# Test")
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "-"])
        }.not_to raise_error
      end

      it "rejects --output-file - with multiple files" do
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "file1.md", "file2.md"])
        }.to raise_error(ArgumentError, "--output-file - can only be used with a single file or STDIN")
      end

      it "allows --output-file - with --style-mode inline" do
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "--style-mode", "inline", "file.md"])
        }.not_to raise_error
      end

      it "allows --output-file - with --style-mode original" do
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "--style-mode", "original", "file.md"])
        }.not_to raise_error
      end

      it "rejects --output-file - with --style-mode external" do
        expect {
          Mint::Commandline.parse!(["--output-file", "-", "--style-mode", "external", "file.md"])
        }.to raise_error(ArgumentError, "--output-file - can only be used with --style-mode inline or --style-mode original")
      end
    end

  end
end