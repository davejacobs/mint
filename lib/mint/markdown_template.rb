require 'tilt/template'
require 'redcarpet'

module Mint
  class MarkdownTemplate < Tilt::Template
    self.default_mime_type = 'text/html'

    def prepare
      @options = options.dup
      
      renderer_options = {
        filter_html: false,
        no_images: false,
        no_links: false,
        no_styles: false,
        escape_html: false,
        safe_links_only: false,
        with_toc_data: false,
        hard_wrap: false,
        prettify: false
      }.merge(@options)
      
      markdown_options = {
        tables: true,
        autolink: true,
        no_intra_emphasis: true,
        fenced_code_blocks: true,
        lax_html_blocks: false,
        strikethrough: true,
        superscript: false,
        footnotes: false,
        highlight: false,
        quote: false,
        disable_indented_code_blocks: false,
        space_after_headers: false,
        underline: false
      }
      
      @renderer = @options.delete(:renderer) || Redcarpet::Render::HTML.new(renderer_options)
      @markdown = Redcarpet::Markdown.new(@renderer, markdown_options)
    end

    def evaluate(scope, locals, &block)
      @markdown.render(data)
    end
  end
end