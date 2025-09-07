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
        command, config, files, help = Mint::Commandline.parse!(["publish", "--output-file", "%{basename}_custom.%{new_extension}", "file.md"])
        
        expect(config.output_file_format).to eq("%{basename}_custom.%{new_extension}")
      end

      it "has default output file format" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "file.md"])
        
        expect(config.output_file_format).to eq("%{basename}.%{new_extension}")
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

      it "parses --file-title flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--file-title", "file.md"])
        
        expect(config.file_title).to be true
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

      it "parses --no-file-title flag" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "--no-file-title", "file.md"])
        
        expect(config.file_title).to be false
      end
    end
  end
end