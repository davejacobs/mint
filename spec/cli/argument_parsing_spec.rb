require "spec_helper"

RSpec.describe "CLI Argument Parsing" do
  describe "Mint::CommandLine.parse" do
    context "with no arguments" do
      it "returns default options and empty argv" do
        result = Mint::CommandLine.parse([])
        
        expect(result[:argv]).to eq([])
        expect(result[:options][:root]).to eq(Dir.getwd)
        expect(result[:options][:scope]).to eq(:local)
        expect(result[:options][:layout_or_style_or_template]).to eq([:template, 'default'])
        expect(result[:help]).to include("Usage: mint")
      end
    end

    context "with template options" do
      it "parses --template option" do
        result = Mint::CommandLine.parse(["--template", "zen", "file.md"])
        
        expect(result[:argv]).to eq(["file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:template, "zen"])
      end

      it "parses --layout option" do
        result = Mint::CommandLine.parse(["--layout", "custom", "file.md"])
        
        expect(result[:argv]).to eq(["file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:layout, "custom"])
      end

      it "parses -l option for layout" do
        result = Mint::CommandLine.parse(["-l", "custom", "file.md"])
        
        expect(result[:argv]).to eq(["file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:layout, "custom"])
      end

      it "parses --style option" do
        result = Mint::CommandLine.parse(["--style", "minimal", "file.md"])
        
        expect(result[:argv]).to eq(["file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:style, "minimal"])
      end

      it "handles short flags for templates" do
        result = Mint::CommandLine.parse(["-t", "pro", "file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:template, "pro"])

        result = Mint::CommandLine.parse(["--layout", "custom", "file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:layout, "custom"])

        result = Mint::CommandLine.parse(["-s", "clean", "file.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:style, "clean"])
      end
    end

    context "with path options" do
      it "parses --root option" do
        result = Mint::CommandLine.parse(["--root", "/custom/path", "file.md"])
        
        expect(result[:options][:root]).to eq("/custom/path")
      end

      it "parses --destination option" do
        result = Mint::CommandLine.parse(["--destination", "output", "file.md"])
        
        expect(result[:options][:destination]).to eq("output")
      end

      it "parses --style-destination option" do
        result = Mint::CommandLine.parse(["--style-destination", "css", "file.md"])
        
        expect(result[:options][:style_destination]).to eq("css")
      end
    end

    context "with output options" do
      it "parses --output-file option" do
        result = Mint::CommandLine.parse(["--output-file", "custom.html", "file.md"])
        
        expect(result[:options][:output_file]).to eq("custom.html")
      end

      it "has default output file format" do
        result = Mint::CommandLine.parse(["file.md"])
        
        expect(result[:options][:output_file]).to eq('#{basename}.#{new_extension}')
      end
    end

    context "with scope options" do
      it "parses --global scope" do
        result = Mint::CommandLine.parse(["--global", "file.md"])
        
        expect(result[:options][:scope]).to eq(:global)
      end

      it "parses --user scope" do
        result = Mint::CommandLine.parse(["--user", "file.md"])
        
        expect(result[:options][:scope]).to eq(:user)
      end

      it "parses --local scope (default)" do
        result = Mint::CommandLine.parse(["--local", "file.md"])
        
        expect(result[:options][:scope]).to eq(:local)
      end

      it "handles short scope flags" do
        result = Mint::CommandLine.parse(["-g"])
        expect(result[:options][:scope]).to eq(:global)

        result = Mint::CommandLine.parse(["-u"])
        expect(result[:options][:scope]).to eq(:user)
      end
    end

    context "with boolean flags" do
      it "parses --recursive flag" do
        result = Mint::CommandLine.parse(["--recursive"])
        
        expect(result[:options][:recursive]).to be true
      end

      it "handles short recursive flag" do
        result = Mint::CommandLine.parse(["-r"])
        
        expect(result[:options][:recursive]).to be true
      end

      it "defaults recursive to false" do
        result = Mint::CommandLine.parse([])
        
        expect(result[:options][:recursive]).to be false
      end
    end

    context "with mixed arguments" do
      it "parses complex argument combinations" do
        args = [
          "--template", "zen",
          "--root", "/custom",
          "--destination", "out", 
          "--recursive",
          "--global",
          "file1.md", "file2.md"
        ]
        
        result = Mint::CommandLine.parse(args)
        
        expect(result[:argv]).to eq(["file1.md", "file2.md"])
        expect(result[:options][:layout_or_style_or_template]).to eq([:template, "zen"])
        expect(result[:options][:root]).to eq("/custom")
        expect(result[:options][:destination]).to eq("out")
        expect(result[:options][:recursive]).to be true
        expect(result[:options][:scope]).to eq(:global)
      end
    end

    context "argument processing utilities" do
      describe ".process_output_format" do
        it "processes basename substitution" do
          result = Mint::CommandLine.process_output_format(
            '#{basename}.html', 
            'document.md'
          )
          
          expect(result).to eq('document.html')
        end

        it "processes original_extension substitution" do
          result = Mint::CommandLine.process_output_format(
            '#{basename}.#{original_extension}.bak',
            'document.md' 
          )
          
          expect(result).to eq('document.md.bak')
        end

        it "processes new_extension substitution" do
          result = Mint::CommandLine.process_output_format(
            '#{basename}.#{new_extension}',
            'document.md'
          )
          
          expect(result).to eq('document.html')
        end

        it "processes complex format strings" do
          result = Mint::CommandLine.process_output_format(
            'output/#{basename}-converted.#{new_extension}',
            'docs/readme.md'
          )
          
          expect(result).to eq('output/readme-converted.html')
        end

        it "handles files without extensions" do
          result = Mint::CommandLine.process_output_format(
            '#{basename}.#{new_extension}',
            'README'
          )
          
          expect(result).to eq('README.html')
        end
      end
    end
  end
end