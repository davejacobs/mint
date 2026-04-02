require "spec_helper"
require "mint/renderers/markdown_renderer"

RSpec.describe Mint::Renderers::Markdown do
  describe ".render" do
    it "renders a list without a preceding blank line" do
      result = described_class.render("Intro:\n- item one\n- item two")

      expect(result).to include("<ul>")
      expect(result).to include("<li>item one</li>")
      expect(result).to include("<li>item two</li>")
    end
  end
end
