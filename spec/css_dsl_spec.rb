require "spec_helper"

module Mint
  describe CSS do
    describe ".stylify" do
      it "translates from human-readable configuration to CSS" do
        table = {
          "Font: Helvetica"         => "font-family: Helvetica",
          'Font: "Lucida Grande"'   => 'font-family: "Lucida Grande"',
          "Font Size: 12pt"         => "font-size: 12pt",
          "Font Color: gray"        => "color: gray",
          "Color: gray"             => "color: gray",
          "Top Margin: 1in"         => "padding-top: 1in",
          "Top: 1in"                => "padding-top: 1in",
          "Bottom: 1in"             => "padding-bottom: 1in",
          "Left: 1in"               => "padding-left: 1in",
          "Right: 1in"              => "padding-right: 1in",
          "Height: 11in"            => "height: 11in",
          "Width: 8in"              => "width: 8in",
          "Columns: 2"              => "column-count: 2",
          "Column Gap: 1in"         => "column-gap: 1in",
          "Orientation: landscape"  => "@page { size: landscape }",
          "Indentation: 0.5in"      => "p+p { text-indent: 0.5in }",
          "Indent: 0.5in"           => "p+p { text-indent: 0.5in }",
          "Bullet: square"          => "li { list-style-type: square }",
          "Bullet Image: img.png"   => "li { list-style-image: url(img.png) }",
          "Before Paragraph: 0.5in" => "p { margin-top: 0.5in }",
          "After Paragraph: 0.5in"  => "p { margin-bottom: 0.5in }"
          # "Smart Typography: On"    => "text-rendering: optimizeLegibility",
          # "Spacing: double"         => "line-height: 2 * ?",
          # "Bullet: checkbox.png"    => "li { list-style-image: url(checkbox.png) }",
        }

        table.each do |human, expected|
          key, value = human.split(":").map(&:strip)
          actual = CSS.stylify(key, value)
          expect(actual).to eq(expected), "Expected '#{human}' to produce '#{expected}', got '#{actual}'"
        end
      end
    end

    describe ".parse" do
      it "transforms a map of human-readable styles into a CSS string" do
        result = CSS.parse({ "Font" => "Helvetica" })
        expect(result).to include("container")
        expect(result).to include("font-family: Helvetica")
      end
    end
  end
end
