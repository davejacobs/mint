require "spec_helper"

RSpec.describe "CLI Configuration Management" do
  describe "configuration operations" do
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          example.run
        end
      end

      describe "Mint::CommandLine.set" do
        it "sets configuration values at local scope" do
          expect {
            Mint::CommandLine.set("layout", "custom", :local)
          }.not_to raise_error
          
          expect(File.exist?(".mint/config.yaml")).to be true
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("custom")
        end

        it "sets configuration values at different scopes" do
          # Test local scope (should work)
          Mint::CommandLine.set("layout", "local-template", :local)
          expect(File.exist?(".mint/config.yaml")).to be true
          
          local_config = YAML.load_file(".mint/config.yaml")
          expect(local_config["layout"]).to eq("local-template")
          
          # For user/global scopes, we'd test the path construction 
          # but can't actually write to those locations in tests
        end

        it "creates config directory if it doesn't exist" do
          expect(File.exist?(".mint")).to be false
          
          Mint::CommandLine.set("style", "minimal", :local)
          
          expect(File.exist?(".mint")).to be true
          expect(File.directory?(".mint")).to be true
          expect(File.exist?(".mint/config.yaml")).to be true
        end

        it "updates existing configuration values" do
          # Set initial value
          Mint::CommandLine.set("layout", "initial", :local)
          initial_config = YAML.load_file(".mint/config.yaml")
          expect(initial_config["layout"]).to eq("initial")
          
          # Update value
          Mint::CommandLine.set("layout", "updated", :local)
          updated_config = YAML.load_file(".mint/config.yaml")
          expect(updated_config["layout"]).to eq("updated")
        end

        it "preserves other configuration values" do
          # Set multiple values
          Mint::CommandLine.set("layout", "my-layout", :local)
          Mint::CommandLine.set("style", "my-style", :local)
          Mint::CommandLine.set("destination", "output", :local)
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("my-layout")
          expect(config["style"]).to eq("my-style")
          expect(config["destination"]).to eq("output")
          
          # Update one value
          Mint::CommandLine.set("layout", "new-layout", :local)
          
          updated_config = YAML.load_file(".mint/config.yaml")
          expect(updated_config["layout"]).to eq("new-layout")
          expect(updated_config["style"]).to eq("my-style") # preserved
          expect(updated_config["destination"]).to eq("output") # preserved
        end

        it "handles various data types" do
          Mint::CommandLine.set("string_value", "text", :local)
          Mint::CommandLine.set("boolean_value", true, :local)
          Mint::CommandLine.set("number_value", 42, :local)
          Mint::CommandLine.set("nil_value", nil, :local)
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["string_value"]).to eq("text")
          expect(config["boolean_value"]).to be true
          expect(config["number_value"]).to eq(42)
          expect(config["nil_value"]).to be_nil
        end

        it "defaults to local scope" do
          Mint::CommandLine.set("test_key", "test_value") # no scope specified
          
          expect(File.exist?(".mint/config.yaml")).to be true
          config = YAML.load_file(".mint/config.yaml")
          expect(config["test_key"]).to eq("test_value")
        end
      end

      describe "Mint::CommandLine.configure" do
        it "sets multiple configuration options at once" do
          options = {
            "layout" => "custom",
            "style" => "minimal", 
            "destination" => "build",
            "verbose" => true
          }
          
          expect {
            Mint::CommandLine.configure(options, :local)
          }.not_to raise_error
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("custom")
          expect(config["style"]).to eq("minimal")
          expect(config["destination"]).to eq("build")
          expect(config["verbose"]).to be true
        end

        it "merges with existing configuration" do
          # Set initial config
          initial_options = {
            "layout" => "default",
            "style" => "default",
            "author" => "Test Author"
          }
          Mint::CommandLine.configure(initial_options, :local)
          
          # Add more options
          additional_options = {
            "layout" => "updated", # should override
            "destination" => "output", # should add
            "verbose" => true # should add
          }
          Mint::CommandLine.configure(additional_options, :local)
          
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("updated") # overridden
          expect(config["style"]).to eq("default") # preserved
          expect(config["author"]).to eq("Test Author") # preserved
          expect(config["destination"]).to eq("output") # added
          expect(config["verbose"]).to be true # added
        end

        it "handles empty options" do
          expect {
            Mint::CommandLine.configure({}, :local)
          }.not_to raise_error
          
          # Should create an empty config file
          expect(File.exist?(".mint/config.yaml")).to be true
        end

        it "handles symbol keys" do
          options = {
            layout: "symbol-layout",
            style: "symbol-style"
          }
          
          Mint::CommandLine.configure(options, :local)
          
          config = YAML.load_file(".mint/config.yaml")
          # Symbol keys remain as symbols in YAML
          expect(config[:layout]).to eq("symbol-layout")
          expect(config[:style]).to eq("symbol-style")
        end
      end

      describe "Mint::CommandLine.config" do
        it "displays current configuration" do
          # Set up some configuration
          Mint::CommandLine.set("layout", "test-layout", :local)
          Mint::CommandLine.set("style", "test-style", :local)
          
          stdout, stderr = capture_output do
            Mint::CommandLine.config
          end
          
          expect(stdout).to include("layout")
          expect(stdout).to include("test-layout")
          expect(stdout).to include("style") 
          expect(stdout).to include("test-style")
        end

        it "shows empty configuration when none exists" do
          stdout, stderr = capture_output do
            Mint::CommandLine.config
          end
          
          # Should show default configuration or empty YAML
          expect(stdout).to include("---") # YAML document start
        end

        it "merges configuration from multiple scopes" do
          # This is more complex to test since we can't easily create
          # user/global configs, but we can test the concept
          setup_basic_config(:local)
          
          stdout, stderr = capture_output do
            Mint::CommandLine.config
          end
          
          expect(stdout).to include("layout")
          expect(stdout).to include("default")
        end
      end

      describe "configuration precedence and merging" do
        describe "Mint.configuration" do
          it "provides default configuration when no files exist" do
            config = Mint.configuration
            
            expect(config).to be_a(Hash)
            expect(config[:layout_or_style_or_template]).to eq([:template, "default"])
          end

          it "merges local configuration with defaults" do
            Mint::CommandLine.set("layout", "custom", :local)
            Mint::CommandLine.set("author", "Test Author", :local)
            
            config = Mint.configuration
            
            expect(config[:layout]).to eq("custom") # from local config
            expect(config[:layout_or_style_or_template]).to eq([:template, "default"]) # from defaults
            expect(config[:author]).to eq("Test Author") # from local config
          end
        end

        describe "Mint.configuration_with" do
          it "merges additional options with configuration" do
            Mint::CommandLine.set("layout", "from-config", :local)
            
            config = Mint.configuration_with({
              style: "from-options",
              destination: "custom-dest"
            })
            
            expect(config[:layout]).to eq("from-config") # from config file
            expect(config[:style]).to eq("from-options") # from options
            expect(config[:destination]).to eq("custom-dest") # from options
          end

          it "allows options to override configuration" do
            Mint::CommandLine.set("layout", "config-layout", :local)
            Mint::CommandLine.set("style", "config-style", :local)
            
            config = Mint.configuration_with({
              layout: "override-layout" # should override config
            })
            
            expect(config[:layout]).to eq("override-layout") # overridden
            expect(config[:style]).to eq("config-style") # preserved
          end

          it "handles scope-specific configuration" do
            # Test that scope flags affect which configs are loaded
            # This is more complex but important for the new scope system
            setup_basic_config(:local)
            
            # Test with different scope selections
            config_local = Mint.configuration_with({ scope: :local })
            config_with_defaults = Mint.configuration_with({})
            
            expect(config_local).to include(:layout)
            expect(config_with_defaults).to include(:layout)
          end
        end
      end

      describe "configuration file handling" do
        it "creates valid YAML files" do
          Mint::CommandLine.set("test", "value", :local)
          
          expect(File.exist?(".mint/config.yaml")).to be true
          
          # Should be parseable YAML
          expect {
            YAML.load_file(".mint/config.yaml")
          }.not_to raise_error
        end

        it "handles special characters in values" do
          special_values = {
            "quotes" => 'Value with "quotes"',
            "newlines" => "Line 1\nLine 2",
            "unicode" => "Unicode: 中文 🚀",
            "symbols" => "Symbols: @#$%^&*()"
          }
          
          special_values.each do |key, value|
            Mint::CommandLine.set(key, value, :local)
          end
          
          config = YAML.load_file(".mint/config.yaml")
          special_values.each do |key, expected_value|
            expect(config[key]).to eq(expected_value)
          end
        end

        it "handles concurrent access gracefully" do
          # This is difficult to test properly, but we can at least
          # verify that multiple rapid operations don't corrupt the file
          10.times do |i|
            Mint::CommandLine.set("key#{i}", "value#{i}", :local)
          end
          
          config = YAML.load_file(".mint/config.yaml")
          10.times do |i|
            expect(config["key#{i}"]).to eq("value#{i}")
          end
        end

        it "preserves file permissions" do
          Mint::CommandLine.set("test", "value", :local)
          
          file_stat = File.stat(".mint/config.yaml")
          original_mode = file_stat.mode
          
          Mint::CommandLine.set("test2", "value2", :local)
          
          new_file_stat = File.stat(".mint/config.yaml")
          expect(new_file_stat.mode).to eq(original_mode)
        end
      end

      describe "error handling" do
        it "handles invalid YAML gracefully" do
          # Create an invalid YAML file
          FileUtils.mkdir_p(".mint")
          File.write(".mint/config.yaml", "invalid: yaml: content: [unclosed")
          
          expect {
            Mint.configuration
          }.not_to raise_error # Should handle gracefully
        end

        it "handles permission errors" do
          # Create config directory but make it read-only
          FileUtils.mkdir_p(".mint")
          File.chmod(0444, ".mint")
          
          begin
            expect {
              Mint::CommandLine.set("test", "value", :local)
            }.to raise_error(Errno::EACCES) # Should fail due to permissions
          ensure
            # Restore permissions for cleanup
            File.chmod(0755, ".mint")
          end
        end

        it "handles missing parent directories" do
          # This should work - the set method should create directories
          expect {
            Mint::CommandLine.set("test", "value", :local)
          }.not_to raise_error
          
          expect(File.exist?(".mint/config.yaml")).to be true
        end
      end
    end
  end
end