require "spec_helper"

RSpec.describe "CLI Argument Parsing" do
  describe "Mint::Commandline.parse!" do
    context "with no arguments" do
      it "returns nil command and default config" do
        command, config, files, help = Mint::Commandline.parse!([])
        
        expect(command).to be_nil
        expect(config.working_directory).to be_a(Pathname)
        expect(config.layout_name).to eq('default')
        expect(config.style_name).to eq('default')
        expect(files).to eq([])
        expect(help).to include("Usage: mint")
      end
    end

    context "with template options" do
      it "parses --template option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--template", "basic", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("basic")
        expect(config.style_name).to eq("basic")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses --layout option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--layout", "custom", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("custom")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses -l option for layout" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "-l", "custom", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("custom")
      end

      it "parses --style option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--style", "minimal", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.style_name).to eq("minimal")
      end

      it "handles short flags for templates" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "-t", "pro", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("pro")
        expect(config.style_name).to eq("pro")
      end
    end

    context "with path options" do
      it "parses --working-dir option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--working-dir", "/custom/path", "file.md"])
        
        expect(config.working_directory).to eq(Pathname.new("/custom/path"))
      end

      it "parses --destination option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--destination", "output", "file.md"])
        
        expect(config.destination_directory).to eq(Pathname.new("output"))
      end

      it "parses --style-destination option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--style-destination", "css", "file.md"])
        
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end

    context "with output options" do
      it "parses --output-file option" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--output-file", "%{name}_custom.%{ext}", "file.md"])
        
        expect(config.output_file_format).to eq("%{name}_custom.%{ext}")
      end

      it "has default output file format" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "file.md"])

        expect(config.output_file_format).to eq("%{name}.%{ext}")
      end

      it "parses --output-file - for stdout" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--output-file", "-", "file.md"])

        expect(config.stdout_mode).to be true
      end
    end

    context "with style mode options" do
      it "parses --style-mode inline" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--style-mode", "inline", "file.md"])
        
        expect(config.style_mode).to eq(:inline)
      end

      it "parses --style-mode external" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--style-mode", "external", "file.md"])
        
        expect(config.style_mode).to eq(:external)
      end
    end

    context "with file handling" do
      it "processes multiple files" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "file1.md", "file2.md", "file3.md"])
        
        expect(files.length).to eq(3)
        expect(files.map(&:basename).map(&:to_s)).to eq(["file1.md", "file2.md", "file3.md"])
      end
    end

    context "style destination behavior" do
      it "automatically sets external mode when style-destination is used" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--style-destination", "css", "file.md"])
        
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end

    context "boolean flags" do
      it "parses --preserve-structure flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--preserve-structure", "file.md"])
        
        expect(config.preserve_structure).to be true
      end

      it "parses --navigation flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--navigation", "file.md"])
        
        expect(config.navigation).to be true
      end

      it "parses --insert-title-heading flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--insert-title-heading", "file.md"])
        
        expect(config.insert_title_heading).to be true
      end

      it "parses --autodrop flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--autodrop", "file.md"])
        
        expect(config.autodrop).to be true
      end
    end

    context "negative boolean flags" do
      it "parses --no-preserve-structure flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--no-preserve-structure", "file.md"])
        
        expect(config.preserve_structure).to be false
      end

      it "parses --no-navigation flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--no-navigation", "file.md"])
        
        expect(config.navigation).to be false
      end

      it "parses --no-insert-title-heading flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--no-insert-title-heading", "file.md"])
        
        expect(config.insert_title_heading).to be false
      end

      it "parses --no-autodrop flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--no-autodrop", "file.md"])

        expect(config.autodrop).to be false
      end
    end

    context "stdout mode validation" do
      it "allows --output-file - with single file" do
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "file.md"])
        }.not_to raise_error
      end

      it "allows --output-file - with STDIN" do
        allow($stdin).to receive(:read).and_return("# Test")
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "-"])
        }.not_to raise_error
      end

      it "rejects --output-file - with multiple files" do
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "file1.md", "file2.md"])
        }.to raise_error(ArgumentError, "--output-file - can only be used with a single file or STDIN")
      end

      it "allows --output-file - with --style-mode inline" do
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "--style-mode", "inline", "file.md"])
        }.not_to raise_error
      end

      it "allows --output-file - with --style-mode original" do
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "--style-mode", "original", "file.md"])
        }.not_to raise_error
      end

      it "rejects --output-file - with --style-mode external" do
        expect {
          Mint::Commandline.parse!(["publish", "--output-file", "-", "--style-mode", "external", "file.md"])
        }.to raise_error(ArgumentError, "--output-file - can only be used with --style-mode inline or --style-mode original")
      end
    end

  end
end