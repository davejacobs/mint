require "sass-embedded"

module Mint
  module CSS
    CONTAINER = "container"

    # Allows for a human-readable DSL to be used to generate CSS. Translates the following:
    #
    # ---
    # Font: Helvetica
    # Margin: 1in
    # Orientation: Landscape
    # ---
    #
    # ... into something like this:
    #
    # #container {
    #   font-family: Helvetica;
    #   padding-left: 1in;
    #   @page { size: landscape };
    # }
    def self.mappings
      {
        font: "font-family",
        font_size: "font-size",
        font_color: "color",
        color: "color",
        top_margin: "padding-top",
        top: "padding-top",
        bottom_margin: "padding-bottom",
        bottom: "padding-bottom",
        left_margin: "padding-left",
        left: "padding-left",
        right_margin: "padding-right",
        right: "padding-right",
        height: "height",
        width: "width",
        columns: "column-count",
        column_gap: "column-gap",
        orientation: "@page { size: %s }",
        indentation: "p+p { text-indent: %s }",
        indent: "p+p { text-indent: %s }",
        bullet: "li { list-style-type: %s }",
        bullet_image: "li { list-style-image: url(%s) }",
        after_paragraph: "p { margin-bottom: %s }",
        before_paragraph: "p { margin-top: %s }"
      }
    end

    def self.stylify(key, value)
      symbol_key = key.to_s.downcase.gsub(' ', '_').to_sym
      selector = mappings[symbol_key]

      if selector.nil?
        ""
      elsif selector.include? "%"
        selector % value
      else
        "#{selector || key}: #{value}"
      end
    end

    def self.parse(style)
      css = style.map {|k,v| stylify(k, v) }.join("\n  ")
      container_scope = "##{CONTAINER}\n  #{css.strip}\n"
      
      # Suppress warnings by capturing $stderr
      original_stderr = $stderr
      $stderr = StringIO.new
      
      result = Sass.compile_string(container_scope, syntax: :indented)
      result.css
    ensure
      $stderr = original_stderr
    end
  end
end
