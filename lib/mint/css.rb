module Mint
  module CSS
    def self.container
      'container'
    end

    # Maps a "DSL" onto actual CSS. This is not yet implemented, but 
    # the plan is to translate this ...
    #
    # ---
    # Font: Helvetica
    # Margin: 1 in
    # Line spacing: 1.25
    #
    # ... into something like:
    #
    # #container {
    #   font: (value specified and cleaned up)
    #   padding-left: (value specified and cleaned up)
    #   ...
    #   p { line-height: (value specified and cleaned up) }
    # }
    def self.mappings
      { 
        font: 'font-family',
        font_size: 'font-size',
        font_color: 'color',
        color: 'color',
        top_margin: 'padding-top',
        top: 'padding-top',
        bottom_margin: 'padding-bottom',
        bottom: 'padding-bottom',
        left_margin: 'padding-left',
        left: 'padding-left',
        right_margin: 'padding-right',
        right: 'padding-right',
        height: 'height',
        width: 'width',
        columns: "column-count",
        column_gap: "column-gap",
        orientation: "@page { size: %s }",
        indentation: 'p+p { text-indent: %s }',
        indent: 'p+p { text-indent: %s }',
        bullet: 'li { list-style-type: %s }',
        bullet_image: 'li { list-style-image: url(%s) }',
        after_paragraph: 'margin-bottom',
        before_paragraph: 'margin-top'
      }
    end

    def self.stylify(key, value)
      selector = mappings[Helpers.symbolize key]

      if selector.nil?
        raise "[error] no mapping found for #{key}" 
      elsif selector.include? '%'
        selector % value
      else
        "#{selector || key}: #{value}"
      end
    end

    def self.parse(style)
      css = style.map {|k,v| format(k, v) }.join("\n  ")
      "##{container} {\n  #{css.strip}\n}"
    end
  end
end
