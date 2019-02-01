# What is Mint?

Mint transforms your plain text documents into beautiful documents. It makes that process as simple (but customizable) as possible.

Why would you want to keep all of your documents as plain text?

- To focus on words and structure when you write
- To be able to apply one style to an entire set of documents with one command
- To keep your documents under version control
- To make your documents available for scripting--for example, text analysis

What does Mint create from these source files? Beautiful, styled HTML ready to print, e-mail, and present.

In a few words: *Mint processes words so you don't have to.*

## The mint command

If you have a plain text document formatted in Markdown or Textile or almost any other templating language, you're ready to go.

The easiest Mint command doesn't require configuration. It transforms a document into HTML and links it to the default stylesheet, which I've designed for you.

Simply type:

    mint publish Minimalism.md

And voil&agrave;, Minimalism.html will show up next to Minimalism.md.

Opening Minimalism.html with your favorite web browser--[Firefox is best for typography][Firefox typography], but Webkit-based browsers (Chrome, Safari) work, too--will show what looks like a word-processed document, complete with big bold headers, italic emphasis, automatically indented and numbered lists, and bullets. If you're in a modern browser, you'll even see ligatures and proper kerning. The page will be on a white canvas that looks like a page, even though you are in a browser.

Sending that page to a printer is as easy as clicking "Print" from your browser. What comes out of your printer will have a 12 pt base font, normal margins, and a not-too-cramped baseline. (Ah the wonder of print stylesheets.)

You can throw as many files as you'd like in. Any commandline argument *not* preceded by an option (e.g., `--template`) or in the `mint` command vocabulary (more on that in a minute) will be interpreted as a file name:

    mint publish Minimalism.md Proposal.md Protocol.md

This command can be tweaked with options and arguments to be more flexible:

    mint publish Minimalism.md --template resume  # specifies a style template
    mint publish Minimalism.md --destination final --style-destination=styles

For a listing of mint options, take [a look at the tutorial][tutorial] or the [full API](http://www.rubydoc.info/github/davejacobs/mint).

## A basic Mint document

Mint is loaded with smart defaults, so if you don't want to configure something--say, the basic HTML skeleton of your document or the output directory--you don't have to. You'll probably be surprised at how easy it is to use out of the box, and how configurable it is.

    document = Mint::Document.new "Minimalism.md"
    document.publish!

If you want to customize your document, though--and that's why I built this library--Mint makes that easy.

To understand Mint's flexibility, you'll want to [take a look at the API][API].

[Firefox typography]: http://opentype.info/blog/2008/06/14/kerning-and-opentype-features-in-firefox-3/ "Firefox 3 supports kerning and automatic ligatures"

## Templates

Templates can be written in any format accepted by the Tilt template interface library. (See [the Tilt TEMPLATES file][Tilt templates] for more information.)

In a template layouts, Ruby calls are sparse but necessary.

If you're designing a layout, you need to indicate where Mint should place your content. For that simple reason, raw HTML files cannot be layouts. Instead, if you want to use HTML templates, you should use the ERB format. These files are essentially HTML with the possibility for Ruby calls. You can even use the .html extension for your files. Just code the dynamic portion using ERB syntax.

Inside your template, use the `content` method to place your source's content.

You will want to point to your document's stylesheet (via a relative URL) from within your layout, usually in the `<head/>` element. Use the `stylesheet` method.

So if you're writing your layout using Haml, the template might look like this:

    !!!
    %html
      %head
        %link(rel="stylesheet" href=stylesheet)

      %body
        #container= content

You can build stylesheets using [CSS][], [SASS/SCSS][] or [Less][]. They will always be compiled for you.

Mint comes preloaded with several styles and layouts.

1. Default
2. Zen
3. Resume\*
4. Protocol
5. Protocol Flow\* - requires Javascript and jQuery

> Note: Starred entries are not yet implemented. If you have a killer
> template you think should be included, send it my way. I'll check
> it out and see if it should be part of the standard template library.
> (Of course, you'll get all the credit.)

I've included a base stylesheet that is useful for setting sensible typographic defaults.

## Plugins: A work in progress

I've designed the beginnings of a plugin system. With this system, you can implement a callback or two and have full control over document creation and sharing. I'll get documentation going soon. For now, look to lib/mint/plugins/epub.rb and bin/mint-epub for an example of how to build one. It's not complete and I'm open to API suggestions. 

This is going to be useful for things like creating actual office documents or e-books or even bound novels. I'm actually thinking that half the power of this library is its plugin system.

[tutorial]: http://github.com/davejacobs/mint/tree/master/doc/API.md
[Tilt templates]: http://github.com/rtomayko/tilt/blob/master/TEMPLATES.md "A listing of all templates supported by Tilt."
[CSS]: http://en.wikipedia.org/wiki/Cascading_Style_Sheets
[SASS/SCSS]: http://sass-lang.com/
[Less]: http://lesscss.org/
