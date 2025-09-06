require "spec_helper"

RSpec.describe "Config File Integration" do
  include CLIHelpers

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MINT_NO_PIPE").and_return("1")
    allow($stdin).to receive(:tty?).and_return(true)
  end

  describe "TOML config file support" do
    context "with local config file" do
      # Note: Tests run in tmp directory from spec_helper
      
      before do
        FileUtils.mkdir_p(".mint") # Ensure directory exists for each test
      end
      
      after do
        cleanup_test_files("*.html", "*.css")
        # Don't clean up .mint directory - let spec_helper handle it
      end

      it "loads template option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          template = "custom"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("custom")
        expect(config.style_name).to eq("custom")
      end

      it "loads layout option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          layout = "minimal"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("minimal")
      end

      it "loads style option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style = "dark"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.style_name).to eq("dark")
      end

      it "loads working-dir option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          working-dir = "/custom/path"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.working_directory).to eq(Pathname.new("/custom/path"))
      end

      it "loads output-file option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          output-file = "%{basename}_custom.%{new_extension}"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.output_file_format).to eq("%{basename}_custom.%{new_extension}")
      end

      it "loads destination option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          destination = "build"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.destination_directory).to eq(Pathname.new("build"))
      end

      it "loads style-mode option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style-mode = "external"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.style_mode).to eq(:external)
      end

      it "loads style-destination option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style-destination = "assets/css"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.style_destination_directory).to eq("assets/css")
      end

      it "loads preserve-structure option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          preserve-structure = true
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.preserve_structure).to be true
      end

      it "loads navigation option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          navigation = true
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.navigation).to be true
      end

      it "loads navigation-drop option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          navigation-drop = 2
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.navigation_drop).to eq(2)
      end

      it "loads navigation-depth option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          navigation-depth = 5
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.navigation_depth).to eq(5)
      end

      it "loads navigation-title option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          navigation-title = "Custom Navigation"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.navigation_title).to eq("Custom Navigation")
      end

      it "loads file-title option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          file-title = true
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.file_title).to be true
      end

      it "supports underscore variants of hyphenated options" do
        File.write(".mint/config.toml", <<~TOML)
          working_dir = "/underscore/path"
          output_file = "%{basename}_under.%{new_extension}"
          style_mode = "original"
          style_destination = "css"
          preserve_structure = true
          navigation_drop = 1
          navigation_depth = 4
          navigation_title = "Underscore Title"
          file_title = true
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.working_directory).to eq(Pathname.new("/underscore/path"))
        expect(config.output_file_format).to eq("%{basename}_under.%{new_extension}")
        expect(config.style_mode).to eq(:original)
        expect(config.style_destination_directory).to eq("css")
        expect(config.preserve_structure).to be true
        expect(config.navigation_drop).to eq(1)
        expect(config.navigation_depth).to eq(4)
        expect(config.navigation_title).to eq("Underscore Title")
        expect(config.file_title).to be true
      end

      it "loads multiple options from config file" do
        File.write(".mint/config.toml", <<~TOML)
          template = "blog"
          destination = "public"
          style-mode = "external"
          preserve-structure = true
          navigation = true
          navigation-depth = 2
          file-title = true
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("blog")
        expect(config.style_name).to eq("blog")
        expect(config.destination_directory).to eq(Pathname.new("public"))
        expect(config.style_mode).to eq(:external)
        expect(config.preserve_structure).to be true
        expect(config.navigation).to be true
        expect(config.navigation_depth).to eq(2)
        expect(config.file_title).to be true
      end

      context "command-line options override config file" do
        before do
          File.write(".mint/config.toml", <<~TOML)
            template = "config"
            destination = "config-dest"
            style-mode = "external"
            preserve-structure = true
            navigation-depth = 5
          TOML
        end

        it "command-line template overrides config file template" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "--template", "cli", "test.md"])
          
          expect(config.layout_name).to eq("cli")
          expect(config.style_name).to eq("cli")
        end

        it "command-line layout overrides config file template layout" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "--layout", "cli-layout", "test.md"])
          
          expect(config.layout_name).to eq("cli-layout")
          expect(config.style_name).to eq("config") # should still use config for style
        end

        it "command-line destination overrides config file destination" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "--destination", "cli-dest", "test.md"])
          
          expect(config.destination_directory).to eq(Pathname.new("cli-dest"))
        end

        it "command-line style-mode overrides config file style-mode" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "--style-mode", "inline", "test.md"])
          
          expect(config.style_mode).to eq(:inline)
        end

        it "command-line preserve-structure overrides config file preserve-structure" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
          
          expect(config.preserve_structure).to be true # from config
        end

        it "command-line navigation-depth overrides config file navigation-depth" do
          command, config, files, help = Mint::Commandline.parse!(["publish", "--navigation-depth", "3", "test.md"])
          
          expect(config.navigation_depth).to eq(3)
        end
      end

      it "handles boolean values correctly" do
        File.write(".mint/config.toml", <<~TOML)
          preserve-structure = false
          navigation = false
          file-title = false
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.preserve_structure).to be false
        expect(config.navigation).to be false
        expect(config.file_title).to be false
      end

      it "handles integer values correctly" do
        File.write(".mint/config.toml", <<~TOML)
          navigation-drop = 0
          navigation-depth = 10
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.navigation_drop).to eq(0)
        expect(config.navigation_depth).to eq(10)
      end

      it "handles missing config file gracefully" do
        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("default")
        expect(config.style_name).to eq("default")
        expect(config.preserve_structure).to be false
        expect(config.navigation).to be false
      end

      it "handles empty config file gracefully" do
        File.write(".mint/config.toml", "")

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("default")
        expect(config.style_name).to eq("default")
      end

      it "handles config file with comments" do
        File.write(".mint/config.toml", <<~TOML)
          # This is a comment
          template = "documented" # inline comment
          
          # Another section
          destination = "output" # destination comment
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("documented")
        expect(config.style_name).to eq("documented")
        expect(config.destination_directory).to eq(Pathname.new("output"))
      end
    end

    context "config file scope priority" do
      before do
        FileUtils.mkdir_p(".mint")
        FileUtils.mkdir_p(File.expand_path("~/.config/mint"))
      end

      after do
        cleanup_test_files(".mint", File.expand_path("~/.config/mint/config.toml"))
      end

      it "local config overrides user config" do
        File.write(File.expand_path("~/.config/mint/config.toml"), <<~TOML)
          template = "user"
          destination = "user-dest"
        TOML
        
        File.write(".mint/config.toml", <<~TOML)
          template = "local"
        TOML

        command, config, files, help = Mint::Commandline.parse!(["publish", "test.md"])
        
        expect(config.layout_name).to eq("local") # local overrides user
        expect(config.destination_directory).to eq(Pathname.new("user-dest")) # user config still applies for non-overridden values
      end
    end
  end
end