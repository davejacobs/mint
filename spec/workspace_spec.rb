require "spec_helper"

module Mint
  describe Workspace do
    around(:each) do |example|
      in_temp_dir do |dir|
        File.write("test.md", "# Test")
        @workspace = begin
          config = Mint::Config.with_defaults(destination_directory: Pathname.new("output"))
          Workspace.new([Pathname.new("test.md")], config)
        end
        example.run
      end
    end
    
    describe "#update_path_basename" do
      it "formats basic filename with new extension" do
        result = @workspace.update_path_basename(Pathname.new("document.md"), 
          new_extension: "html", format_string: "%{name}.%{ext}")
        expect(result).to eq(Pathname.new("document.html"))
      end

      it "uses custom format string" do
        result = @workspace.update_path_basename(Pathname.new("document.md"), 
          new_extension: "html", format_string: "%{name}_output.%{ext}")
        expect(result).to eq(Pathname.new("document_output.html"))
      end

      it "provides access to original extension" do
        result = @workspace.update_path_basename(Pathname.new("document.md"), 
          new_extension: "html", format_string: "%{name}.%{original_ext}.%{ext}")
        expect(result).to eq(Pathname.new("document.md.html"))
      end

      it "handles files without extension" do
        result = @workspace.update_path_basename(Pathname.new("README"), 
          new_extension: "html", format_string: "%{name}.%{ext}")
        expect(result).to eq(Pathname.new("README.html"))
      end
    end

    describe "autodrop functionality" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          create_template_directory("default")
          example.run
        end
      end

      describe "#calculate_autodrop_levels" do
        it "returns 0 for single file" do
          File.write("readme.md", "# README")
          workspace = Workspace.new([Pathname.new("readme.md")], Config.defaults)
          expect(workspace.send(:calculate_autodrop_levels_for, [Pathname.new("readme.md")])).to eq(0)
        end

        it "calculates common prefix for multiple files" do
          FileUtils.mkdir_p(["common/docs", "common/src"])
          files = [
            Pathname.new("common/docs/api.md"),
            Pathname.new("common/docs/guide.md"), 
            Pathname.new("common/src/code.md")
          ]
          files.each {|file| File.write(file, "# Content") }
          workspace = Workspace.new(files, Config.defaults)
          expect(workspace.send(:calculate_autodrop_levels_for, files)).to eq(1)
        end

        it "handles deeply nested common paths" do
          FileUtils.mkdir_p(["very/deeply/nested/dir1", "very/deeply/nested/dir2"])
          files = [
            Pathname.new("very/deeply/nested/dir1/file1.md"),
            Pathname.new("very/deeply/nested/dir2/file2.md")
          ]
          files.each {|file| File.write(file, "# Content") }
          workspace = Workspace.new(files, Config.defaults)
          expect(workspace.send(:calculate_autodrop_levels_for, files)).to eq(3)
        end

        it "returns 0 when no common prefix exists" do
          FileUtils.mkdir_p(["docs", "src"])
          files = [
            Pathname.new("docs/guide.md"),
            Pathname.new("src/code.md")
          ]
          files.each {|file| File.write(file, "# Content") }
          workspace = Workspace.new(files, Config.defaults)
          expect(workspace.send(:calculate_autodrop_levels_for, files)).to eq(0)
        end
      end

      describe "autodrop behavior in publishing" do
        it "drops common levels from destination paths when autodrop is enabled" do
          FileUtils.mkdir_p(["common/docs", "common/src", "output"])
          create_markdown_path("common/docs/api.md", "# API Documentation")
          create_markdown_path("common/docs/guide.md", "# User Guide")
          create_markdown_path("common/src/code.md", "# Code Documentation")
          
          files = [
            Pathname.new("common/docs/api.md"),
            Pathname.new("common/docs/guide.md"),
            Pathname.new("common/src/code.md")
          ]
          
          config = Config.with_defaults(
            destination_directory: Pathname.new("output"),
            preserve_structure: true,
            autodrop: true
          )
          
          workspace = Workspace.new(files, config)
          workspace.publish!
          
          # Files should be placed without the "common" prefix
          expect(File.exist?("output/docs/api.html")).to be true
          expect(File.exist?("output/docs/guide.html")).to be true
          expect(File.exist?("output/src/code.html")).to be true
          
          # Files should NOT be placed with the full path
          expect(File.exist?("output/common/docs/api.html")).to be false
        end

        it "preserves full paths when autodrop is disabled" do
          FileUtils.mkdir_p(["common/docs", "common/src", "output"])
          create_markdown_path("common/docs/api.md", "# API Documentation")
          create_markdown_path("common/src/code.md", "# Code Documentation")
          
          files = [
            Pathname.new("common/docs/api.md"),
            Pathname.new("common/src/code.md")
          ]
          
          config = Config.with_defaults(
            destination_directory: Pathname.new("output"),
            preserve_structure: true,
            autodrop: false
          )
          
          workspace = Workspace.new(files, config)
          workspace.publish!
          
          # Files should be placed with full path preserved
          expect(File.exist?("output/common/docs/api.html")).to be true
          expect(File.exist?("output/common/src/code.html")).to be true
          
          # Files should NOT be placed without the common prefix
          expect(File.exist?("output/docs/api.html")).to be false
        end

        it "doesn't affect paths when preserve_structure is false" do
          FileUtils.mkdir_p(["common/docs", "output"])
          create_markdown_path("common/docs/api.md", "# API Documentation")
          create_markdown_path("common/docs/guide.md", "# User Guide")
          
          files = [
            Pathname.new("common/docs/api.md"),
            Pathname.new("common/docs/guide.md")
          ]
          
          config = Config.with_defaults(
            destination_directory: Pathname.new("output"),
            preserve_structure: false,
            autodrop: true
          )
          
          workspace = Workspace.new(files, config)
          workspace.publish!
          
          # Files should be placed directly in destination without structure
          expect(File.exist?("output/api.html")).to be true
          expect(File.exist?("output/guide.html")).to be true
        end
      end
    end
  end
end