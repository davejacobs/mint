# What is Mint?

Mint transforms your plain text documents into beautiful documents. It makes the process simple but customizable.

Why would you want to keep all of your documents as plain text?

- To focus on words and structure when you write
- To control style with a single command, independently of document structure
- To keep your text and formatting under version control
- To make your text amenable to scripting--for example, text analysis

What does Mint create from these source files? Beautiful, styled HTML ready to print, e-mail, export, and present.

In a few words: *Mint processes words so you don't have to.*

## The mint command

If you have a plain text document formatted in Markdown or Textile or almost any other templating
language, you're ready to go.

The easiest Mint command doesn't require configuration. It transforms a document into HTML and links
it to the default stylesheet, which I've designed for you.

Simply type:

    mint publish Document.md

And voil&agrave;, Minimalism.html will show up next to Document.md.

Opening Minimalism.html with your favorite web browser--[Firefox is best for typography][Firefox
typography], but Webkit-based browsers (Chrome, Safari) work, too--will show what looks like a
word-processed document, complete with big bold headers, italic emphasis, automatically indented
and numbered lists, and bullets. If you're in a modern browser, you'll even see ligatures and
proper kerning. The page will be on a white canvas that looks like a page, even though you are in a
browser.

Sending that page to a printer is as easy as clicking "Print" from your browser. What comes out of
your printer will have a 12 pt base font, normal margins, and a not-too-cramped baseline. (Ah the
wonder of print stylesheets.)

You can throw as many files as you'd like in. Any commandline argument *not* preceded by an option
(e.g., `--template`) or in the `mint` command vocabulary (more on that in a minute) will be
interpreted as a file name:

    mint publish Document.md Proposal.md

This command can be tweaked with options and arguments to be more flexible:

    mint publish Document.md --template resume                      # specifies a style template
    mint publish Document.md --style-destination styles             # creates external stylesheet in styles directory
    mint publish Document.md --style-destination styles/custom.css  # creates external stylesheet at specific path

For a listing of mint options, take [a look at the tutorial][tutorial] or the [full API](http://www.rubydoc.info/github/davejacobs/mint).

## A basic Mint document

Mint is loaded with smart defaults, so if you don't want to configure something--say, the basic HTML
skeleton of your document or the output directory--you don't have to. You'll probably be surprised
at how easy it is to use out of the box, and how configurable it is.

    document = Mint::Document.new("Document.md")
    document.publish!

If you want to customize your document, though--and that's why I built this library--Mint makes that
easy with explicit parameters:

    # Create a document with external stylesheet
    document = Mint::Document.new("Document.md", 
                                  style_destination: "css",
                                  template: "zen")
    document.publish!

    # Create with specific layout and style
    document = Mint::Document.new("Resume.md",
                                  destination: "output",
                                  layout: "resume",
                                  style: "professional")
    document.publish!

To understand Mint's flexibility, you'll want to [take a look at the API][API].

[Firefox typography]: http://opentype.info/blog/2008/06/14/kerning-and-opentype-features-in-firefox-3/ "Firefox 3 supports
kerning and automatic ligatures"

## Templates

Templates can be written in any format accepted by the Tilt template interface library. (See [the
Tilt TEMPLATES file][Tilt templates] for more information.)

In a template layouts, Ruby calls are sparse but necessary.

If you're designing a layout, you need to indicate where Mint should place your content. For that
simple reason, raw HTML files cannot be layouts. Instead, if you want to use HTML templates, you
should use the ERB format. These files are essentially HTML with the possibility for Ruby calls. You
can even use the .html extension for your files. Just code the dynamic portion using ERB syntax.

Inside your template, use the `content` method to place your source's content.

For stylesheets, use the `stylesheet_tag` method, which automatically handles both inline and external stylesheets based on the document's style mode:

So if you're writing your layout using Haml, the template might look like this:

    !!! 
    %html 
      %head 
        = stylesheet_tag
      %body 
        #container= content

The `stylesheet_tag` method will generate either:
- `<style>...</style>` tags with inlined CSS for inline mode (default)
- `<link rel="stylesheet" href="...">` tags for external stylesheets

You can create template stylesheets using [CSS][] or [SCSS][].

Mint comes preloaded with a few templates to get you started.

1. Default
2. Zen
3. Nord
4. Nord Dark

## Plugins: A work in progress

I've designed the beginnings of a plugin system. With this system, you can implement a callback or
two and have full control over document creation and sharing. I'll get documentation going soon. For
now, look to lib/mint/plugins/epub.rb and bin/mint-epub for an example of how to build one. It's not
complete and I'm open to API suggestions.

This is going to be useful for things like creating actual office documents or e-books or even bound
novels. I'm actually thinking that half the power of this library is its plugin system.

[tutorial]: http://github.com/davejacobs/mint/tree/master/doc/API.md
[Tilt templates]: http://github.com/rtomayko/tilt/blob/master/TEMPLATES.md "A listing of all templates supported by Tilt."
[CSS]: http://en.wikipedia.org/wiki/Cascading_Style_Sheets
[SASS/SCSS]: http://sass-lang.com/
[Less]: http://lesscss.org/