Introduction
------------

Mint is an agile, lightweight solution for your documents.

Mint manages your documents in a decentralized but consistent way. It frees you from bloated word processors. Mint brings together standards and common templating languages for a clean, agile approach to documents. It uses HTML outside of the web. Leverages text for loads of different views. Keeps your data and formatting separate. In a word: simplifies. In a couple of words: kicks ass.

In a few more: *Mint processes words so you don't have to.*

The `mint` command
---------------------

The easiest Mint command doesn't require configuration. It will transform the specified document into HTML and link it to the default stylesheet, which will be output in the same directory as the source documents. (If you have a ./templates/default/ subdirectory, the templates found in that directory will be used.)

    mint Minimalism.md                    # creates Minimalism.html

And voil&agrave;, Minimalism.html will show up next to Minimalism.md.

Opening Minimalism.html with your favorite web browser--[Firefox is best for typography][Firefox typography], but Webkit-based browsers (Chrome, Safari) work, too--will show what looks like a word-processed document, complete with big bold headers, italic emphasis, automatically indented and numbered lists, and bullets. If you're in a modern browser, you'll even see ligatures and proper kerning. The page will be on a white canvas that looks like a page, even though you are in a browser.

Sending that page to a printer is as easy as clicking "Print" from your browser. What comes out of your printer will have a 12 pt base font, normal margins, and a not-too-cramped baseline. (Ah the wonder of print stylesheets.)

You can throw as many files as you'd like in. Any commandline argument *not* preceded by an option (e.g., `--template`) or in the `mint` command vocabulary (more on that in a minute) will be interpreted as a file name:

    mint Minimalism.md Proposal.md Protocol.md

This command can be tweaked with options and arguments to be more flexible:

    mint Minimalism.md --template resume  # specifies a style template
    mint Minimalism.md --destination final --style-destination=styles

You can pass several options to `mint`. For a listing of these options, take [a look at the API][API].

A basic Mint document
---------------------

Mint is loaded with smart defaults, so if you don't want to configure something--say, the basic HTML skeleton of your document or the output directory--you don't have to. You'll probably be surprised at how easy it is to use out of the box, and how configurable it is.

    document = Document.new 'Minimalism.md'
    document.publish!

If you want to customize your document, though--and that's why I built this library--Mint makes that easy.

To understand Mint's flexibility, you'll want to [take a look at the API][API].

[Firefox typography]: http://opentype.info/blog/2008/06/14/kerning-and-opentype-features-in-firefox-3/ "Firefox 3 supports kerning and automatic ligatures"

Designing a template
-------------------------

Templates can be written in any format accepted by the Tilt template interface library. (See [the Tilt TEMPLATES file][Tilt templates] for more information.)

Templates are rendered in the context of the document they are "about", so Mint documents give you convenience methods you can easily use in your templates.

### Place your content, point to your styles ###

In Mint layouts, Ruby calls are sparse but necessary.

If you're designing a layout, you need to indicate where Mint should place your content. For that simple reason, raw HTML files cannot be layouts. Instead, if you want to use HTML templates, you should use the ERB format. These files are essentially HTML with the possibility for Ruby calls. You can even use the .html extension for your files. Just code the dynamic portion using ERB syntax.

Inside your template, use the `content` method to place your source's content.

You will want to point to your document's stylesheet (via a relative URL) from within your layout, usually in the `<head/>` element. Use the `stylesheet` method.

So if you're writing your layout using Haml, the template might look like this:

    !!!
    %html
      %head
        %link(rel='stylesheet' href=stylesheet)

      %body
        #container= content

### Style your content ###

You can build stylesheets using [CSS][], [SASS/SCSS][] or [Less][]. They will
always be compiled. They will only be copied, though, if you specify a style
destination.

[Tilt templates]: http://github.com/rtomayko/tilt/blob/master/TEMPLATES.md "A listing of all templates supported by Tilt."
[CSS]: http://en.wikipedia.org/wiki/Cascading_Style_Sheets
[SASS/SCSS]: http://sass-lang.com/
[Less]: http://lesscss.org/

Mint comes preloaded with several styles and layouts.

1. Default
2. Pro
3. Resume\*
4. Protocol
5. Protocol Flow\* - requires Javascript and jQuery

> Note: Starred entries are not yet implemented. If you have a killer
> template you think should be included, send it my way. I'll check
> it out and see if it should be part of the standard template library.
> (Of course, you'll get all the credit.)

I've included a base stylesheet that is useful for setting sensible typographic defaults.

[API]: http://github.com/davejacobs/mint/tree/master/doc/API.md
