module Mint
  module CSS
    def container
      'container'
    end

    # Mappings from "DSL" to actual CSS. The plan is to translate
    # this into something like:
    #
    # #container {
    #   font: (value specified and cleaned up)
    #   padding-left: (value specified and cleaned up)
    #   ...
    #   p { line-height: (value specified and cleaned up) }
    # }
    def mappings
      { 
        font: 'font',
        color: 'color',
        top_margin: 'padding-top',
        bottom_margin: 'padding-bottom',
        left_margin: 'padding-left',
        right_margin: 'padding-right',
        top: 'padding-top',
        bottom: 'padding-bottom',
        left: 'padding-left',
        right: 'padding-right',
        height: 'height',
        width: 'width',
        line_spacing: 'p { line-height: %s }',
        bullet: 'bullet-shape',
        indentation: 'text-indent',
        after_paragraph: 'margin-bottom',
        before_paragraph: 'margin-top',
        smart_typography: 'optimizeLegibility'
      }
    end

    def format(key, value)
      selector = mappings[Helpers.symbolize key]

      if selector.include? '%'
        selector % value
      else
        "#{selector || key}: #{value}"
      end
    end

    def parse(style)
      css = style.map {|k,v| format(k, v) }.join("\n  ")
      "##{container} {\n  #{css.strip}\n}"
    end
  end
end
