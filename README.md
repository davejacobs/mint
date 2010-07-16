*The following is a **rough draft** of the current Mint design, along with my future plans for the library and tool. The code is not yet tested, though it will be as soon as I decide on a framework, and the binary does not yet work. This is concept stuff, people.*

If I believed in slogans...
---------------------------

I don't actually believe in tag lines, but if Mint were to have one, it might be one of these:

- Value your words. Leave the formatting up to us.
- Reuse your ideas. Reuse your formats. Keep them Mint fresh.
- Mint once, remix as needed.

Introduction
------------

Mint is an agile, lightweight solution for your documents.

Mint manages your documents in a decentralized way. It frees you from bloated word processors. Mint brings together standards and common templating languages for a clean, agile approach to documents. It uses HTML outside of the web. Leverages text for tons of different views. Keeps your data and formatting separate. In a word: simplifies. In a couple of words: kicks ass.

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

1. Jake has text files formatted as Markdown-style text. He has traditionally published these as blog entries, which works well because his webserver takes care of processing the Markdown, generating HTML, and styling it with his static CSS. Jake has no way of visualizing his documents without a webserver running. He likes the convenience of centralized CSS styles that he can update once and cascade everywhere. He does not like depending on a webserver for static pages. Jake wants a document management system where source files are written in Markdown but are "printed" into HTML and styled with centralized sheets he creates himself.

2. Donna has traditionally used a WYSIWYG word processor to create, edit, version, and present ideas in her personal and school life (not work). She wants her documents to exist forever without breaking standards: she wants them to be completely future-compatible. Therefore, she wants to migrate away from her proprietary word processor. She wants a migration tool to make the initial conversion. Interoperability with other people is not required. As long as she can view and print formatted documents, keeping source files as plaintext, she is happy.

3. Bertrande wants to build a styles gallery that previews certain styles on Textile-formatted documents using a web application... (finish later)

4. Marina wants to convert all her proprietary processed documents to Markdown for future compatibility, but wants to share these documents with friends at work. Interoperability is important here. The friends should be able to easily view *and* edit *and* annotate all documents.

II. The Mint library
--------------------

This section discusses the Mint library API. Read on for the mint binary.

### A basic Mint document ###

Mint is loaded with smart defaults, so if you don't want to configure something--say, the basic HTML skeleton of your document or the output name or director--you don't have to. You'll probably be surprised at how easy it is to use out of the box, and how configurable it is.

    document = Document.new '~/Documents/Minimalism.md'
    document.press

And voilà, you will find the following next to Minimalism.md in the same directory:

- Minimalism.html
- styles/default.css

Opening Minimalism.html with your favorite web browser--[Firefox is best for typography][Firefox typography]--will show what looks like a word processed document, complete with big bolded headers, italic emphasis, automatically numbered lists, and bullets. The page will be on a white canvas that looks like a page, even though you are in a browser.

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

  2. If you specify a template name that is also the name of an existing file in your working directory, Mint will use the file and not look for a template. (It is unlikely you'll have an extension-less file named 'normal' or 'default' in your working directory.) If you do specify an existing file, the path/file will be resolved from the directory where you're calling Mint (the 'working directory'). To use Mint this way (and I don't see this as more than a temporary solution) you'll probably want to call Mint from within your source's directory. Alternatively, you can use [`Dir.chdir`][Dir::chdir method] for the same effect.

  3. You can specify nil if you don't want a style to be rendered. This is useful if you're pointing a lot of documents to one stylesheet and only want to Mint the stylesheet one time. `Mint::Project` uses this technique to render a style once, independently of its documents.

- `:destination` lets you organize your output. It directs Mint to output the template or document into one of root's subdirectories. There is an option to specify a separate `:style_destination`, which is resolved relative to `:destination`.

  Defaults:

        :destination => ''
        :style_destination => ''

  Notes:

  1. `:destination` *must* refer to a directory (existing or not) and not a file. If you want to specify the output file name, use the `:name` parameter.

  2. `:style_destination` is resolved relative to `:destination` so that packaging styles inside document directories is easy. (This supports the common case where you will want a subdirectory called 'styles' to hold your style files.)

  3. If either value is nil, it is simply ignored.

- `:name` is the name of the output file, which will end up in `:destination/`. `:style_name` is the name of the stylesheet output file and will show up in `:destination/:style_destination/`.

  Defaults:

        :name => ''         # guess from source file name
        :style_name => ''   # same as above

  Notes:

  1. If empty, the name of a document or template comes from it's source file. (Minimalism.md will turn into Minimalism.html without configuration.)

In summary: if `:directory` is unspecified, it will be the directory where your content file ends up. The rendered style files will be placed directly into this directory unless given a specific destination. The output names will come from their source files unless you specify a name.

### Examples ###

At this point, a couple of example may be useful.

The following are possible:

    content = '~/Documents/Minimalism.md'

    Document.new content

    Document.new content, :destination => 'directory', :name => 'final.html'
    Document.new content, :destination => 'directory'

    Style.new 'normal'
    Style.new '~/Sites/Commons/Styles/normal.css', :destination => 'styles', :name => 'style.css'

  > Note: A style's destination is specified as :destination when passed directly to the file or as :style_destination when passed to a document or project

    Style.new '~/Sites/Commons/style/normal.css'
    Style.new 'Commons/style/normal.css'

If block-style initiation is your thing:

    Document.new content do |d|
      d.root = 'my-book'
      d.name = 'my-book-final-draft.html'

      d.style 'normal' do |s|
        s.destination = 'styles'
        s.name = 'stylesheet.css'
      end
    end

> Note: Block-style indentation passes the block to you after initializing
> the document with default values. So you do not need to worry about
> specifying each argument. Anything you specify will override what
> is already there.

One warning: when you initialize a document via a block, do not try
the following:

    # The wrong way to block-initialize a document:

    Document.new content do |d|
      d.style_destination = 'styles'
    end

Because :style\_destination translates internally to :destination (so that it can be passed to the style initializer), setting :style\_destination is meaningless in a document block.

*(Should this change? Maybe I'll fix that.)*

[Dir::chdir method]: http://ruby-doc.org/core/classes/Dir.html#M002314 "You can change the current directory context with Dir::chdir(path)"

III. Designing a template
-------------------------

Templates can be written in any format accepted by the Tilt template interface library. (See [the Tilt TEMPLATES file][Tilt templates] for more information.)

Templates are rendered in the context of the document they are "about", so Mint documents give you convenience methods you can easily use in your templates.

### Place your content, point to your styles ###

If you're designing a layout, you need to indicate where Mint should place your content. Therefore, raw HTML files cannot be layouts. Instead, if you want to use HTML templates, you should change the extension to .erb. These files are essentially HTML with the possibility for Ruby calls.

Inside your template, use the keyword (well, actually the method) `content` to place your source's content.

You will want to point to your document's stylesheet (via a relative URL) from within your layout, usually in the `<head/>` element. Use the keyword `stylesheet`.

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
        %link{ :rel => 'stylesheet', :href => stylesheet }

      %body
        #container= content

### Style your content ###

You can build stylesheets using [CSS][], [Sass/Scss][] or [Less][].

[Tilt templates]: http://github.com/rtomayko/tilt/blob/master/TEMPLATES.md "A listing of all templates supported by Tilt."
[CSS]: http://en.wikipedia.org/wiki/Cascading_Style_Sheets
[Sass/Scss]: http://sass-lang.com/
[Less]: http://lesscss.org/

Mint comes preloaded with several styles and layouts:

  > Note: These aren't all designed yet. Also, if you have a killer
  > template you think should be included, send it my way. I'll check
  > it out and see if it should be part of the standard template library.
  > (Of course, you'll get all the credit.)

1. Default
2. Serif Pro
3. Sans Pro
4. Protocol
5. Protocol Flow - requires Javascript
6. Resume

IV. The Mint path
-----------------

Mint's path tells the library where to search for named templates. It can be useful for other things, too, especially for extensions and tools that use the library. The Mint path is flexible and something that you can modify, even from the command line. (Just export `MINT\_PATH`!)

So here's the rundown.

When you instantiate a layout or style with a string or symbol, Mint will first search the current directory for that file (or, if the file includes path information, Mint will follow that path in search of the file). If that file does not exist, Mint will search its path in order until it finds the appropriate template. If no template is found, it will fall back to the default template.

The default Mint path (in order) is:

- the current working directory
- ${HOME}/.mint
- /usr/share/mint (or whatever your system uses for system-wide configuration - Mint will make a smart guess)
- the Mint gem directory (which holds the Mint-approved templates)

Templates should be in a directory named templates. Inside this directory, there should be a subdirectory for each template:

- ${MINT_PATH}/templates/normal/style.css
- ${MINT_PATH}/templates/normal/layout.haml

Normally a style will go best with its complement layout. However, layouts and styles can be mixed and matched at your discretion. This is especially true where you are not using stylesheets to format specific DOM IDs or classes you're expecting to find in your layout. (In other words, this works best when your stylesheet focuses on modifying typography and not page layout.)

V. The `mint` command
---------------------

*The `mint` command is not yet functional.*

### The basic `mint` command ###

The easiest Mint command doesn't require configuration. It will transform all of your documents into HTML and link all of them to the default stylesheet, which will be output in the same directory as the source documents.

    mint

If you have a ./templates/default/ subdirectory, the templates found in that directory will be used.

Don't want all of your documents minted just yet? Specify a file:

    mint Minimalism.md

This command can be tweaked with options and arguments to be more flexible:

    mint Minimalism.md Final.html         # specifies an output file
    mint Minimalism.md --template=resume  # specifies a style template
    mint Minimalism.md --destination=output --style-destination=styles

### Mint options &amp; shortcuts ###

You can pass several options to `mint`. Following the Unix tradition, common options have a short and long form.

The following correspond to the parameters you can pass to `Mint::Document.new`, as described in [The Mint library][]:

- `--template, -T`
- `--layout, -L`
- `--style, -S`
- `--destination, -D`
- `--name, -N`
- `--style-destination`
- `--style-name`

Other options have nothing to do with document configuration but are there for convenience:

- `--verbose, -v` - will output all rendering results
- `--simulation, -s` - will not actually render any files

[The Mint library]: #ii_the_mint_library

### Mint configuration ###

A more powerful and reconfigurable version of Mint uses config files so that you can get the power of convention with the flexibility of configuration. You can configure Mint on a global, user-wide, or directory-specific scale to avoid specifying configuration information every time you call the command.

To set a local (directory-specific) configuration option, call `mint set`:

    mint set [local] --template=serif-professional --destination=final

This will create a config file: ./.mint/config.yaml

It will contain:

    template: serif-professional
    destination: final

From now on, calling mint in this directory will automatically draw on these two options.

You can also set user-wide options:

    mint set user --template=professional --destination=html

Doing so will create the same style config file, but in your system's user-wide configuration location:

- In Linux and other FHS-compliant systems, and on Mac OS X this will be in ~/.mint/config.yaml
- In Windows, this will be *(somewhere dumb...)*

Finally, you can set global options for all users:

    mint set global --template=normal --destination=mint

This configuration affects all users and will be put somewhere appropriate:

- In Linux and on other FHS-compliant systems, this will be in /usr/share/mint
- On Mac OS X, this is going to land somewhere unknown, possibly inside of  /Library/Application Support/Mint or /usr/share/mint
- On Windows, this will end up *(somewhere dumber than before)*

These options give you the power to unify a directory or user or all users under a certain default layout and style. These options are all overridden via commandline options and only provide defaults so that you can save typing common commands. Mint selects the most specific option possible, starting with the commandline, then checking local the config file, and finally moving to the user-wide and global config files.

If configuration options get complicated, it may be useful to list all active defaults, with more specific options replacing more general ones per above:

    mint config

[Yaml]: http://yaml.org/

### Editing files in a project ###

Inside of a directory, you can edit any stylesheet or document template that would normally be used in your current context without delving into the Mint templates directories.

    # Selects the first template in your path with the appropriate name:
    mint edit --layout default
    mint edit --style normal

    # Selects the template from a specified context
    mint edit global --layout default

Mint will open the appropriate file in the editor specified by EDITOR. The same short forms listed earlier apply here:

    mint edit -L normal
    mint edit -S normal

VI. The future of Mint
----------------------

This section documents features that do not yet exist, but that I would like to have in future versions of Mint.

### Packages ###

Sometimes, it may be useful to "finalize" the design of a document, for example, with publications. The best way I can think of to do this is to package the document's output file along with its style in a zipped package, which can be read by the following:

    mint open --package Minimalism --in firefox

To package a document with its stylesheet, as a sort of a printing:

    mint package document.md --name Document

Eventually, this could include multiple output formats, like HTML4, HTML5, PDF and ePub. The format opened by the `mint open` command could be determined by the application you choose to open it with. (This would take some serious OS hacking, I think.)

When that does happen, you'll also be able to set the default version of the document that will open using:

    mint set [local] --package-default html5
    
### More ###

More ideas are coming soon...