require "spec_helper"

module Mint
  describe Workspace do
    describe ".format_output_file" do
      it "formats basic filename with new extension" do
        result = Workspace.format_output_file("document.md")
        expect(result).to eq("document.html")
      end

      it "uses custom format string" do
        result = Workspace.format_output_file("document.md", 
          format_string: "%{name}_output.%{ext}")
        expect(result).to eq("document_output.html")
      end

      it "provides access to original extension" do
        result = Workspace.format_output_file("document.md", 
          format_string: "%{name}.%{original_ext}.%{ext}")
        expect(result).to eq("document.md.html")
      end

      it "handles files without extension" do
        result = Workspace.format_output_file("README")
        expect(result).to eq("README.html")
      end
    end
  end
end