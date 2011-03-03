*The following is a **rough draft** of the current Mint design, along with my future plans for the library and tool. The templates are not all there yet (that's the next step) and my first plugins aren't quite there. That said, I'm excited about where this library is going to go.*

If I believed in slogans...
---------------------------

I don't actually believe in tag lines, but if Mint were to have one, it might be one of these:

- Value your words. Leave the formatting up to us.
- Reuse your ideas. Reuse your formats. Keep them Mint fresh.
- Mint once, remix as needed.

Introduction
------------

Mint is an agile, lightweight solution for your documents.

Mint manages your documents in a decentralized but consistent way. It frees you from bloated word processors. Mint brings together standards and common templating languages for a clean, agile approach to documents. It uses HTML outside of the web. Leverages text for loads of different views. Keeps your data and formatting separate. In a word: simplifies. In a couple of words: kicks ass.

In a few more: *Mint processes words so you don't have to.*

Table of contents
-----------------

I. Use cases  
II. The Mint library  
III. Designing a template  
IV. The Mint path  
V. The `mint` command  
VI. Future directions and tools

I. Use cases
------------

1. Jake has text files formatted as Markdown-style text. He has traditionally published these as blog entries, which works well because his webserver takes care of processing the Markdown, generating HTML, and styling it with his static CSS. Jake has no way of visualizing his documents without a webserver running. He likes the convenience of centralized CSS styles that he can update once and cascade everywhere. He does not like depending on a webserver for static pages, i.e., his local documents. Jake wants a document management system where source files are written in Markdown but are "printed" into HTML and styled with centralized sheets he creates himself. In some cases, he merely wants to tweak the typography settings of a solid existing style. Above all, he wants simplicity: he does not want to have to put his documents into a certain structure in order for them to be rendered. And he wants default styles so that he doesn't have to create them on his own.

2. Donna has traditionally used a WYSIWYG word processor to create, edit, version, and present ideas in her personal and school life (not work). She wants her documents to exist forever without breaking standards: she wants them to be completely future-proof. Therefore, she wants to migrate away from her proprietary word processor. (Even non-proprietary word processors are really too heavyweight for her text-centered documents.) She wants a migration tool to make the initial conversion. Interoperability with other people is not required. As long as she can view and print formatted documents, keeping source files as plain text, she is happy.

3. Marina wants to convert all her proprietary processed documents to Markdown for future compatibility, but wants to share these documents with friends at work. Interoperability is important here. The friends should be able to easily view *and* edit *and* annotate all documents. Marina will be happiest if she has a simple GUI that can export documents to an open-source document format that's interoperable with word processors.

II. The Mint library
--------------------

This section discusses the Mint library API. This library encapsulates the idea of a styled document, which is composed of a stylesheet, a layout and content. Mint makes combining those seemless. See **The `mint` command** for more information on an easy-to-use binary.

### A basic Mint document ###

Mint is loaded with smart defaults, so if you don't want to configure something--say, the basic HTML skeleton of your document or the output directory--you don't have to. You'll probably be surprised at how easy it is to use out of the box, and how configurable it is.

    document = Document.new 'Minimalism.md'
    document.mint

And voilà, Minimalism.html will show up next to Minimalism.md.

Opening Minimalism.html with your favorite web browser--[Firefox is best for typography][Firefox typography], but Webkit-based browsers (Chrome, Safari) work, too--will show what looks like a word-processed document, complete with big bold headers, italic emphasis, automatically indented and numbered lists, and bullets. If you're in a modern browser, you'll even see ligatures and proper kerning. The page will be on a white canvas that looks like a page, even though you are in a browser.

Sending that page to a printer is as easy as clicking "Print" from your browser. What comes out of your printer will have a 12 pt base font, normal margins, and a not-too-cramped baseline. (Ah the wonder of print stylesheets.)

If you want to customize your document, though--and that's why I built this library--Mint makes that easy.

[Firefox typography]: http://opentype.info/blog/2008/06/14/kerning-and-opentype-features-in-firefox-3/ "Firefox 3 supports kerning and automatic ligatures"

### Customizing Mint ###

To understand how the library works, with and without configuration, it is helpful to look at the options you can pass to the library and what their defaults are.

You can pass any of the following to a new document:

- `:layout` and `:style` are names of templates or file names. They can be overridden by `:template`, which sets both to the same name.

  Defaults:

        :template => 'default'

  Notes:

  1. If you specify a template name here, Mint will search its paths in order (see **The Mint Path** for more details) for a template with that name. A template file looks like the following:

            ${MINT_PATH}/templates/template_name/style.css
            ${MINT_PATH}/templates/template_name/layout.haml

  2. If you specify a template name that is also the name of an existing file in your working directory, Mint will use the file and not look for a template. (It is unlikely you'll have an extension-less file named 'normal' or 'default' in your working directory, so don't worry about this edge case.) If you do specify an existing file, the path/file will be resolved from the directory where you're calling Mint (the 'working directory'). To use Mint this way (and I don't see this as more than a temporary solution) you'll probably want to call Mint from within your source's directory. Alternatively, you can use [`Dir.chdir`][Dir::chdir method] for the same effect.

- `:destination` lets you organize your output. It directs Mint to write the template or document to one of root's subdirectories. There is an option to specify a separate `:style_destination`, which is resolved relative to `:destination`.

  Defaults:

        :destination => nil
        :style_destination => nil

  Notes:

  1. `:destination` *must* refer to a directory (existing or not) and not a file.

  2. `:style_destination` is resolved relative to `:destination` so that packaging styles inside document directories is easy. (This supports the common case where you will want a subdirectory called 'styles' to hold your style files.) When `:style_destination` is nil (default), the stylesheet will not be copied anywhere. Instead, your document will link to the rendered stylesheet in place. If `:style_destination` is 'inline', your style will be included inline with your published document.

### Examples ###

At this point, a couple of examples may be useful.

The following are possible:

    include Mint
    content = '~/Documents/Minimalism.md'
    
    Document.new content
    Document.new content, :destination => 'directory', :style => 'serif-pro'
    Document.new content, :style => Style.new(:normal)
    
    Style.new 'normal'
    Style.new :normal
    Style.new '~/Sites/Common Styles/normal.css', :destination => 'styles'
    Style.new '~/Sites/Common Styles/normal.css', 
      :style_destination => 'inline'
    Style.new 'Common Styles/normal.css'

> Note: A style's destination is specified as `:destination` when passed directly to the file or as `:style_destination` when passed to a document or project

If block-style initiation is your thing:

    Document.new content do |d|
      d.destination = 'final'
      d.template = 'resume'
    end

> Note: Block-style indentation passes the block to you *after* initializing
> the document with default values. So you do not need to worry about
> specifying each argument. Anything you specify will override what
> is already there.

One warning: when you initialize a document via a block, do not try
the following:

    Document.new content do |d|
      # The wrong way to block-initialize a style destination:
      d.style_destination = 'styles'
    end

Because `:style_destination` translates internally to `:destination` (so that it can be passed to the style initializer), setting `:style_destination` is meaningless in a document block. Instead, you should do the following:

    Document.new content do |d|
      # The right way to block-initialize a style destination:
      d.style.destination = 'styles'
    end

*(Should this change? Maybe I'll fix that.)*

[Dir::chdir method]: http://ruby-doc.org/core/classes/Dir.html#M002314 "You can change the current directory context with Dir::chdir(path)"

III. Designing a template
-------------------------

Templates can be written in any format accepted by the Tilt template interface library. (See [the Tilt TEMPLATES file][Tilt templates] for more information.)

Templates are rendered in the context of the document they are "about", so Mint documents give you convenience methods you can easily use in your templates.

### Place your content, point to your styles ###

In Mint layouts, Ruby calls are sparse but necessary.

If you're designing a layout, you need to indicate where Mint should place your content. For that simple reason, raw Html files cannot be layouts. Instead, if you want to use Html templates, you should use the Erb format. These files are essentially Html with the possibility for Ruby calls. You can even use the .html extension for your files. Just code the dynamic portion using Erb syntax.

Inside your template, use the `content` method to place your source's content.

You will want to point to your document's stylesheet (via a relative URL) from within your layout, usually in the `<head/>` element. Use the `stylesheet` method.

So if you're writing your layout using Erb, the template might look like this:

    <!doctype html>
    <html>
      <head>
        <link rel='stylesheet' href='<%= stylesheet %>' />
      </head>

      <body>
        <div id='container'>
          <%= content %>
        </div>
      </body>
    </html>

The same layout in Haml would be:

    !!!
    %html
      %head
        %link(rel='stylesheet' href=stylesheet)

      %body
        #container= content

### Style your content ###

You can build stylesheets using [Css][], [Sass/Scss][] or [Less][]. They will
always be compiled. They will only be copied, though, if you specify a style
destination.

[Tilt templates]: http://github.com/rtomayko/tilt/blob/master/TEMPLATES.md "A listing of all templates supported by Tilt."
[Css]: http://en.wikipedia.org/wiki/Cascading_Style_Sheets
[Sass/Scss]: http://sass-lang.com/
[Less]: http://lesscss.org/

Mint comes preloaded with several styles and layouts.

1. Default
2. Serif Pro
3. Sans Pro
4. Protocol
5. Protocol Flow - requires Javascript and jQuery
6. Resume

> Note: These aren't all designed yet. Also, if you have a killer
> template you think should be included, send it my way. I'll check
> it out and see if it should be part of the standard template library.
> (Of course, you'll get all the credit.)

I'm going to build a template extension system soon so that you can easily base your template off of another one using its template name, and without knowing its location on disk.

IV. The Mint path
-----------------

Mint's path tells the library where to search for named templates. It can be useful for other things, too, especially for extensions and tools that use the library (for example, for storing config files for the `mint` command). The Mint path is flexible and something that you can modify, even from the command line. (Just export `MINT_PATH`=`your:colon-separated-paths:here`. Just make sure to specify higher-priority paths before lower-priority ones.)

So here's the rundown.

When you name a layout or style with a string or symbol, Mint will first search the current directory for that file or file path. If that file does not exist, Mint will search its path in order until it finds the appropriate template. If no template is found, it will fall back to the default template.

The default Mint path (in order) is:

- the current working directory
- `${HOME}/.mint`
- `/usr/share/mint` (or whatever your system uses for system-wide configuration - Mint will make a smart guess)
- the Mint gem directory (which holds the Mint-approved templates)

Templates should be in a directory named templates. Inside this directory, there should be a subdirectory for each template:

- `${MINT_PATH}/templates/normal/style.sass`
- `${MINT_PATH}/templates/normal/layout.haml`

Normally a style will go best with its layout complement. However, layouts and styles can be mixed and matched at your discretion. This is especially true where you are primarily customizing DOM elements with your stylesheet instead of targeting specific IDs or classes you're expecting to find. (In other words, this works best when your stylesheet focuses on modifying typography and not page layout.)

V. The `mint` command
---------------------

*The `mint` command is almost functional. Testing is in development.*

### The basic `mint` command ###

The easiest Mint command doesn't require configuration. It will transform the specified document into HTML and link it to the default stylesheet, which will be output in the same directory as the source documents. (If you have a ./templates/default/ subdirectory, the templates found in that directory will be used.)

    mint Minimalism.md                    # creates Minimalism.html

You can throw as many files as you'd like in. Any commandline argument *not* preceded by an option (e.g., `--template`) or in the `mint` command vocabulary (more on that in a minute) will be interpreted as a file name:

    mint Minimalism.md Proposal.md Protocol.md

This command can be tweaked with options and arguments to be more flexible:

    mint Minimalism.md --template resume  # specifies a style template
    mint Minimalism.md --destination final --style-destination=styles

### Mint options & shortcuts ###

You can pass several options to `mint`. Following the Unix tradition, common options have a short and long form.

The following correspond to the parameters you can pass to `Mint::Document.new`, as described in [The Mint library][]:

- `--template, -t`
- `--layout, -l`
- `--style, -s`
- `--destination, -d`
- `--style-destination, -n`

There are also scoping options, both for the `set` and `edit` commands:

- `--global, -G`
- `--user, -U`
- `--local, -L`

*If you've used `MINT_PATH` to set up Mint, then you should be aware that
`--local` refers to the first element, `--user` refers to the second, and
`--global` refers to the third.*

Other options have nothing to do with document configuration but are there for convenience:

- `--verbose, -v` - will output all rendering results
- `--simulation, -s` - will not actually render any files

[The Mint library]: #ii_the_mint_library

### `mint` command vocabulary ###

Not all commandline arguments will be read as files. `mint` has a certain vocabulary that you can use, for example, to manipulate configuration options or edit layout files.

Currently, the `mint` vocabulary consists of `set`, `edit`, and `config`. 

### `mint` configuration ###

`mint` is capable of using config files to harness the power of convention without sacrificing the flexibility of configuration. You can configure `mint` on a global, user-wide, or local (directory-specific) scale to avoid passing commandline options every time you call `mint`.

To set a local (directory-specific) configuration option, call `mint set`:

    mint set [--local] template=serif-professional

This will create (or update) a config file: ./.mint/config.yml

It will contain:

    template: serif-professional

From now on, calling `mint` in this directory will automatically draw on this option. (Commandline options will override any file-based options.)

You can also set user-wide options:

    mint set --user template=professional

Doing so will create the same style config file, but in your system's user-wide configuration location:

- In Linux and other FHS-compliant systems, and on Mac OS X this 
  will be in ~/.mint/config.yaml
- In Windows, this will be *(somewhere dumb...)*

Finally, you can set global options for all users:

    mint set --global template=normal

This configuration affects all users and will be put somewhere appropriate:

- In Linux and on other FHS-compliant systems, this will be in /usr/share/mint
- On Mac OS X, this is going to land somewhere yet to be determined, possibly inside of /Library/Application Support/Mint or /usr/share/mint -- I haven't decided
- On Windows, this will end up *(somewhere dumber than before)*

These options give you the power to unify a directory or user or all users under a certain default layout and style. These options are all overridden via commandline options and only provide defaults so that you can save typing common commands. `mint` selects the most specific option possible, starting with the commandline, then checking local the config file, and finally moving to the user-wide and global config files.

If configuration options get complicated, it may be useful to list all active defaults, with more specific options replacing more general ones per above:

    mint config

[Yaml]: http://yaml.org/

### Editing files in a project ###

Inside of a directory, you can edit any stylesheet or document template that would normally be used in your current context without delving into the Mint templates directories, except of course the default templates provided with Mint.

    # Selects the first template in your path with the appropriate name:
    mint edit --layout my-fun-layout
    mint edit --style snazzy-styles

    # Selects the template from a specified context
    mint edit user --layout my-fun-layout

Mint will open the appropriate file in the editor specified by EDITOR. The same short forms listed earlier apply here:

    mint edit -L normal
    mint edit -S normal

VI. The future of Mint
----------------------

This section documents features that do not yet exist, but that I would like to have in future versions of Mint.

### Composed styles ###

Not everyone wants to code an entire stylesheet every time he wants a new look. In fact, the most common use case for stylesheets is probably tweaking typography. For this reason (and to make this tool as accessible as possible), I want to implement a feature where you can select one stylesheet as a base and implement tweaks on top of that file, using a Yaml-based DSL. Of course Css makes this easy enough, but I want to implement this feature in such a way that it is easy and intuitive for everyone.

### Packages ###

Sometimes, it may be useful to "finalize" the design of a document, for example, with publications. The best way I can think of to do this is to package the document's output file with its style inline. To do so, simply add the package option:

    mint package document.md
