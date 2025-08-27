require "spec_helper"

RSpec.describe "CLI Template Management" do
  describe "template operations" do
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          example.run
        end
      end

      describe "Mint::CommandLine.templates" do
        it "lists templates from specified scope" do
          create_template_directory("custom")
          create_template_directory("minimal")
          
          stdout, stderr = capture_output do
            Mint::CommandLine.templates("", :local)
          end
          
          expect(stdout).to include("custom")
          expect(stdout).to include("minimal")
        end

        it "filters templates by pattern" do
          create_template_directory("custom-dark")
          create_template_directory("custom-light") 
          create_template_directory("minimal")
          
          stdout, stderr = capture_output do
            Mint::CommandLine.templates("custom", :local)
          end
          
          expect(stdout).to include("custom-dark")
          expect(stdout).to include("custom-light")
          expect(stdout).not_to include("minimal")
        end

        it "shows template paths in output" do
          create_template_directory("test-template")
          
          stdout, stderr = capture_output do
            Mint::CommandLine.templates("", :local)
          end
          
          expect(stdout).to include("test-template")
          expect(stdout).to include(".mint/templates/test-template")
        end

        it "handles empty template directory" do
          stdout, stderr = capture_output do
            Mint::CommandLine.templates("", :local)
          end
          
          expect(stdout.strip).to eq("")
        end
      end

      describe "Mint::CommandLine.install" do
        it "installs a layout template file" do
          layout_content = "<html><body><%= yield %></body></html>"
          create_template_file("custom.erb", :layout, layout_content)
          
          expect {
            Mint::CommandLine.install("custom.erb", "mytemplate", :local)
          }.not_to raise_error
          
          installed_file = ".mint/templates/mytemplate/layout.erb"
          expect(File.exist?(installed_file)).to be true
          expect(File.read(installed_file)).to eq(layout_content)
        end

        it "installs a style template file" do
          style_content = "body { background: #f0f0f0; }"
          create_template_file("custom.css", :style, style_content)
          
          expect {
            Mint::CommandLine.install("custom.css", "mystyle", :local)  
          }.not_to raise_error
          
          installed_file = ".mint/templates/mystyle/style.css"
          expect(File.exist?(installed_file)).to be true
          expect(File.read(installed_file)).to eq(style_content)
        end

        it "creates template directory if it doesn't exist" do
          create_template_file("layout.erb", :layout)
          
          expect(File.exist?(".mint/templates/newtemplate")).to be false
          
          Mint::CommandLine.install("layout.erb", "newtemplate", :local)
          
          expect(File.exist?(".mint/templates/newtemplate")).to be true
          expect(File.exist?(".mint/templates/newtemplate/layout.erb")).to be true
        end

        it "determines template type by file extension" do
          # Create different file types
          File.write("layout.haml", "%html\n  %body= yield")
          File.write("style.scss", "$primary: #333;\nbody { color: $primary; }")
          
          Mint::CommandLine.install("layout.haml", "haml-template", :local)
          Mint::CommandLine.install("style.scss", "scss-template", :local)
          
          expect(File.exist?(".mint/templates/haml-template/layout.haml")).to be true
          expect(File.exist?(".mint/templates/scss-template/style.scss")).to be true
        end

        it "raises error for non-existent source file" do
          expect {
            Mint::CommandLine.install("nonexistent.erb", "test", :local)
          }.to raise_error(RuntimeError, /No such file/)
        end

      end

      describe "Mint::CommandLine.uninstall" do
        it "removes an entire template directory" do
          create_template_directory("removeme", with_layout: true, with_style: true)
          
          expect(File.exist?(".mint/templates/removeme")).to be true
          
          Mint::CommandLine.uninstall("removeme", :local)
          
          expect(File.exist?(".mint/templates/removeme")).to be false
        end

        it "handles non-existent templates gracefully" do
          expect {
            Mint::CommandLine.uninstall("nonexistent", :local)
          }.to raise_error(Errno::ENOENT)
        end
      end

      describe "Mint::CommandLine.edit" do
        it "opens layout template in editor" do
          create_template_directory("editable", with_layout: true)
          template_file = ".mint/templates/editable/layout.erb"
          
          silence_output do
            mock_editor do
              expect {
                Mint::CommandLine.edit("editable", :layout, :local)
              }.not_to raise_error
            end
          end
        end

        it "opens style template in editor" do
          create_template_directory("editable", with_style: true)
          
          silence_output do
            mock_editor do
              expect {
                Mint::CommandLine.edit("editable", :style, :local)
              }.not_to raise_error
            end
          end
        end

        it "prompts to create template if it doesn't exist" do
          # Mock STDIN to simulate user input
          allow(STDIN).to receive(:gets).and_return("y\n")
          
          silence_output do
            mock_editor do
              expect {
                Mint::CommandLine.edit("newtemplate", :layout, :local)
              }.not_to raise_error
            end
          end
          
          expect(File.exist?(".mint/templates/newtemplate/layout.erb")).to be true
        end

        it "cancels creation when user says no" do
          allow(STDIN).to receive(:gets).and_return("n\n")
          
          silence_output do
            expect {
              Mint::CommandLine.edit("newtemplate", :layout, :local)
            }.to raise_error(SystemExit)
          end
        end

        it "rejects invalid template types" do
          silence_output do
            expect {
              Mint::CommandLine.edit("template", :invalid, :local)
            }.to raise_error(SystemExit, /Invalid template type/)
          end
        end

        it "requires template name" do
          silence_output do
            expect {
              Mint::CommandLine.edit("", :layout, :local)
            }.to raise_error(SystemExit, /No template specified/)
            
            expect {
              Mint::CommandLine.edit(nil, :layout, :local)
            }.to raise_error(SystemExit, /No template specified/)
          end
        end
      end

      describe "template creation helpers" do
        describe "Mint::CommandLine.create_template" do
          it "creates a layout template with default content" do
            template_file = Mint::CommandLine.create_template("newlayout", :layout, :local)
            
            expect(File.exist?(template_file)).to be true
            content = File.read(template_file)
            expect(content).to include("<!DOCTYPE html>")
            expect(content).to include("<%= content %>")
            expect(template_file).to end_with("/layout.erb")
          end

          it "creates a style template with default content" do
            template_file = Mint::CommandLine.create_template("newstyle", :style, :local)
            
            expect(File.exist?(template_file)).to be true
            content = File.read(template_file)
            expect(content).to include("body {")
            expect(content).to include("font-family:")
            expect(template_file).to end_with("/style.css")
          end

          it "creates template directory structure" do
            Mint::CommandLine.create_template("organized", :layout, :local)
            
            expect(File.exist?(".mint/templates/organized")).to be true
            expect(File.directory?(".mint/templates/organized")).to be true
          end

          it "rejects invalid template types" do
            silence_output do
              expect {
                Mint::CommandLine.create_template("test", :invalid, :local)
              }.to raise_error(SystemExit, /Invalid template type/)
            end
          end
        end

        describe "default template content" do
          it "provides valid HTML5 layout template" do
            content = Mint::CommandLine.default_layout_content
            
            expect(content).to include("<!DOCTYPE html>")
            expect(content).to include("<html>")
            expect(content).to include("<title>Document</title>")
            expect(content).to include("<%= content %>")
            expect(content).to include("<%= style %>")
          end

          it "provides basic CSS style template" do
            content = Mint::CommandLine.default_style_content
            
            expect(content).to include("body {")
            expect(content).to include("font-family:")
            expect(content).to include("max-width:")
            expect(content).to include("code {")
          end
        end
      end

      describe "template lookup integration" do
        it "finds installed templates via lookup methods" do
          create_template_directory("findme", with_layout: true, with_style: true)
          
          layout_file = Mint.lookup_layout("findme")
          style_file = Mint.lookup_style("findme")
          template_dir = Mint.lookup_template("findme")
          
          expect(layout_file).to include("findme/layout.erb")
          expect(style_file).to include("findme/style.css")
          expect(template_dir.to_s).to include("findme")
          expect(File.exist?(layout_file)).to be true
          expect(File.exist?(style_file)).to be true
          expect(File.directory?(template_dir)).to be true
        end

        it "raises TemplateNotFoundException for missing templates" do
          expect {
            Mint.lookup_layout("missing")
          }.to raise_error(Mint::TemplateNotFoundException)
          
          expect {
            Mint.lookup_style("missing") 
          }.to raise_error(Mint::TemplateNotFoundException)
          
          expect {
            Mint.lookup_template("missing")
          }.to raise_error(Mint::TemplateNotFoundException)
        end
      end
    end
  end
end