require "spec_helper"

RSpec.describe "CLI Argument Parsing" do
  describe "Mint::Commandline.parse!" do
    before do
      # Ensure we don't think we're in a pipe for tests
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("MINT_NO_PIPE").and_return("1")
      allow($stdin).to receive(:tty?).and_return(true)
    end
    context "with no arguments" do
      it "returns help command and default config" do
        command, help, config, files = Mint::Commandline.parse!([])
        
        expect(command).to eq("help")
        expect(config.working_directory).to be_a(Pathname)
        expect(config.layout_name).to eq('default')
        expect(config.style_name).to eq('default')
        expect(help).to include("Usage: mint")
        expect(files).to eq([])
      end
    end

    context "with template options" do
      it "parses --template option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--template", "basic", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("basic")
        expect(config.style_name).to eq("basic")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses --layout option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--layout", "custom", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("custom")
        expect(files.map(&:basename).map(&:to_s)).to include("file.md")
      end

      it "parses -l option for layout" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "-l", "custom", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("custom")
      end

      it "parses --style option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--style", "minimal", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.style_name).to eq("minimal")
      end

      it "handles short flags for templates" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "-t", "pro", "file.md"])
        
        expect(command).to eq("publish")
        expect(config.layout_name).to eq("pro")
        expect(config.style_name).to eq("pro")
      end
    end

    context "with path options" do
      it "parses --root option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--root", "/custom/path", "file.md"])
        
        expect(config.working_directory).to eq(Pathname.new("/custom/path"))
      end

      it "parses --destination option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--destination", "output", "file.md"])
        
        expect(config.destination_directory).to eq(Pathname.new("output"))
      end

      it "parses --style-destination option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--style-destination", "css", "file.md"])
        
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end

    context "with output options" do
      it "parses --output-file option" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--output-file", "%{basename}_custom.%{new_extension}", "file.md"])
        
        expect(config.output_file_format).to eq("%{basename}_custom.%{new_extension}")
      end

      it "has default output file format" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "file.md"])
        
        expect(config.output_file_format).to eq("%{basename}.%{new_extension}")
      end
    end

    context "with style mode options" do
      it "parses --style-mode inline" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--style-mode", "inline", "file.md"])
        
        expect(config.style_mode).to eq(:inline)
      end

      it "parses --style-mode external" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--style-mode", "external", "file.md"])
        
        expect(config.style_mode).to eq(:external)
      end
    end

    context "with file handling" do
      it "processes multiple files" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "file1.md", "file2.md", "file3.md"])
        
        expect(files.length).to eq(3)
        expect(files.map(&:basename).map(&:to_s)).to eq(["file1.md", "file2.md", "file3.md"])
      end
    end

    context "style destination behavior" do
      it "automatically sets external mode when style-destination is used" do
        command, help, config, files = Mint::Commandline.parse!(["publish", "--style-destination", "css", "file.md"])
        
        expect(config.style_mode).to eq(:external)
        expect(config.style_destination_directory).to eq("css")
      end
    end
  end
end