require 'redcarpet'

module Mint
  module Renderers
    class Markdown
      def self.render(text, variables = {}, **markdown_options)
        # Use default rendering options (all extra options turned off)
        # See documentation for more information:
        # https://github.com/vmg/redcarpet#darling-i-packed-you-a-couple-renderers-for-lunch
        renderer_options = {
          # filter_html: false,
          # no_images: false,
          # no_links: false,
          # no_styles: false,
          # escape_html: false,
          # safe_links_only: false,
          # with_toc_data: false,
          # hard_wrap: false,
          # prettify: false
        }
        
        markdown_options = {
          tables: true,
          autolink: true,
          no_intra_emphasis: true,
          fenced_code_blocks: true,
          strikethrough: true,
          superscript: true,
          footnotes: true,
          highlight: true,
          quote: true,
          space_after_headers: true,
          underline: true,
          # Additional options
          # lax_html_blocks: false,
          # disable_indented_code_blocks: false
          }.merge(markdown_options)
        
        renderer = Redcarpet::Render::HTML.new(renderer_options)
        parser = Redcarpet::Markdown.new(renderer, markdown_options)
        parser.render text
      end
    end
  end
end