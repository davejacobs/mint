require "spec_helper"

RSpec.describe "Config File Integration" do
  include CLIHelpers


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

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.layout_name).to eq("custom")
        expect(config.style_name).to eq("custom")
      end

      it "loads layout option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          layout = "minimal"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.layout_name).to eq("minimal")
      end

      it "loads style option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style = "dark"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.style_name).to eq("dark")
      end


      it "loads output-file option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          output-file = "%{ext}_custom.%{ext}"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.output_file_format).to eq("%{ext}_custom.%{ext}")
      end

      it "loads destination option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          destination = "build"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.destination_directory).to eq(Pathname.new("build"))
      end

      it "loads style-mode option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style-mode = "external"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.style_mode).to eq(:external)
      end

      it "loads style-destination option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          style-destination = "assets/css"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.style_destination_directory).to eq("assets/css")
      end

      it "loads preserve-structure option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          preserve-structure = true
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.preserve_structure).to be true
      end

      it "loads navigation option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation = true
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation]).to be true
      end


      it "loads navigation-depth option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation-depth = 5
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation_depth]).to eq(5)
      end

      it "loads navigation-title option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation-title = "Custom Navigation"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation_title]).to eq("Custom Navigation")
      end

      it "loads autodrop option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          autodrop = false
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.autodrop).to be false
      end

      it "loads insert-title-heading option from config file" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          insert-title-heading = true
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:insert_title_heading]).to be true
      end

      it "loads multiple options from config file" do
        File.write(".mint/config.toml", <<~TOML)
          template = "blog"
          destination = "public"
          style-mode = "external"
          preserve-structure = true

          [options]
          navigation = true
          navigation-depth = 2
          insert-title-heading = true
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.layout_name).to eq("blog")
        expect(config.style_name).to eq("blog")
        expect(config.destination_directory).to eq(Pathname.new("public"))
        expect(config.style_mode).to eq(:external)
        expect(config.preserve_structure).to be true
        expect(config.options[:navigation]).to be true
        expect(config.options[:navigation_depth]).to eq(2)
        expect(config.options[:insert_title_heading]).to be true
      end

      context "command-line options override config file" do
        before do
          File.write(".mint/config.toml", <<~TOML)
            template = "config"
            destination = "config-dest"
            style-mode = "external"
            preserve-structure = true

            [options]
            navigation-depth = 5
          TOML
        end

        it "command-line template overrides config file template" do
          config, files, help = Mint::Commandline.parse!(["--template", "cli", "test.md"])
          
          expect(config.layout_name).to eq("cli")
          expect(config.style_name).to eq("cli")
        end

        it "command-line layout overrides config file template layout" do
          config, files, help = Mint::Commandline.parse!(["--layout", "cli-layout", "test.md"])
          
          expect(config.layout_name).to eq("cli-layout")
          expect(config.style_name).to eq("config") # should still use config for style
        end

        it "command-line destination overrides config file destination" do
          config, files, help = Mint::Commandline.parse!(["--destination", "cli-dest", "test.md"])
          
          expect(config.destination_directory).to eq(Pathname.new("cli-dest"))
        end

        it "command-line style-mode overrides config file style-mode" do
          config, files, help = Mint::Commandline.parse!(["--style-mode", "inline", "test.md"])
          
          expect(config.style_mode).to eq(:inline)
        end

        it "command-line preserve-structure overrides config file preserve-structure" do
          config, files, help = Mint::Commandline.parse!(["test.md"])
          
          expect(config.preserve_structure).to be true # from config
        end

        it "command-line navigation-depth overrides config file navigation-depth" do
          config, files, help = Mint::Commandline.parse!(["--opt", "navigation-depth=3", "test.md"])

          expect(config.options[:navigation_depth]).to eq(3)
        end
      end

      context "--no- flags override config file boolean values" do
        before do
          File.write(".mint/config.toml", <<~TOML)
            preserve-structure = true
            navigation = true
            insert-title-heading = true
          TOML
        end

        it "--no-preserve-structure overrides config file preserve-structure=true" do
          config, files, help = Mint::Commandline.parse!(["--no-preserve-structure", "test.md"])
          
          expect(config.preserve_structure).to be false
        end



        it "positive flags still work to override config file false values" do
          File.write(".mint/config.toml", <<~TOML)
            preserve-structure = false
            navigation = false
            insert-title-heading = false
          TOML

          config, files, help = Mint::Commandline.parse!(["--preserve-structure", "--opt", "navigation", "--opt", "insert-title-heading", "test.md"])

          expect(config.preserve_structure).to be true
          expect(config.options[:navigation]).to be true
          expect(config.options[:insert_title_heading]).to be true
        end

      end

      it "handles boolean values correctly" do
        File.write(".mint/config.toml", <<~TOML)
          preserve-structure = false

          [options]
          navigation = false
          insert-title-heading = false
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.preserve_structure).to be false
        expect(config.options[:navigation]).to be false
        expect(config.options[:insert_title_heading]).to be false
      end

      it "handles integer values correctly" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation-depth = 10
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation_depth]).to eq(10)
      end

      it "handles missing config file gracefully" do
        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.layout_name).to eq("default")
        expect(config.style_name).to eq("default")
        expect(config.preserve_structure).to be true
        expect(config.options[:navigation]).to be nil
      end

      it "handles empty config file gracefully" do
        File.write(".mint/config.toml", "")

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
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

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.layout_name).to eq("documented")
        expect(config.style_name).to eq("documented")
        expect(config.destination_directory).to eq(Pathname.new("output"))
      end

      it "loads nested options section" do
        File.write(".mint/config.toml", <<~TOML)
          template = "test"

          [options]
          navigation = true
          navigation-depth = 3
          navigation-title = "Nested Navigation"
          insert-title-heading = true
          custom-option = "value"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation]).to be true
        expect(config.options[:navigation_depth]).to eq(3)
        expect(config.options[:navigation_title]).to eq("Nested Navigation")
        expect(config.options[:insert_title_heading]).to be true
        expect(config.options[:custom_option]).to eq("value")
      end

      it "prefers nested options over flat options" do
        File.write(".mint/config.toml", <<~TOML)
          # Flat options (legacy)
          navigation = false
          navigation-title = "Flat Title"

          # Nested options (preferred)
          [options]
          navigation = true
          navigation-title = "Nested Title"
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation]).to be true
        expect(config.options[:navigation_title]).to eq("Nested Title")
      end

      it "handles false values in options" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation = false
          insert-title-heading = false
          sidebar = true
        TOML

        config, files, help = Mint::Commandline.parse!(["test.md"])

        expect(config.options[:navigation]).to be false
        expect(config.options[:insert_title_heading]).to be false
        expect(config.options[:sidebar]).to be true
      end

      it "command-line negated options override config file" do
        File.write(".mint/config.toml", <<~TOML)
          [options]
          navigation = true
          insert-title-heading = true
        TOML

        config, files, help = Mint::Commandline.parse!(["--opt", "no-navigation", "test.md"])

        expect(config.options[:navigation]).to be false
        expect(config.options[:insert_title_heading]).to be true
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

        config, files, help = Mint::Commandline.parse!(["test.md"])
        
        expect(config.layout_name).to eq("local") # local overrides user
        expect(config.destination_directory).to eq(Pathname.new("user-dest")) # user config still applies for non-overridden values
      end
    end
  end
end