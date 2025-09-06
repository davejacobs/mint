# Mint tutorial

Mint is a publishing tool that converts plain text Markdown documents into beautifully formatted HTML and PDF files.

Mint lets you:

- Convert Markdown documents to styled HTML (PDFs and ePubs are planned)
- Publish entire digital gardens (collections of linked Markdown files)
- Apply consistent styling across all your documents
- Work entirely offline

## Installation

Install Mint through Ruby:

    gem install mint

## Basic usage

Convert a Markdown file to HTML:

    mint publish Document.md

This creates `Document.html` in the current directory.

### Using templates

Apply a template for automatic styling:

    mint publish Document.md --template nord

### Output directory

Specify where the output file goes:

    mint publish Document.md --destination final-draft

### Mix and match layouts and styles

Use different layouts and stylesheets:

    mint publish Document.md --layout default --style nord

### Extract titles from filenames

Use the filename as the document title:

    mint publish my-article.md --file-title

This removes the `.md` extension from the filename and uses it as both the HTML title and an H1 heading.

### Preserve directory structure

Keep your source directory structure in the output:

    mint publish docs/**/*.md --destination public --preserve-structure

For all available options, see `man mint`.

## Digital gardens

Convert multiple linked Markdown files into a connected website:

    mint publish my-garden/**/*.md --destination public --template garden

This creates an HTML site with:
- All your Markdown files converted to HTML
- Links between files preserved  
- Navigation sidebar showing all pages
- Consistent styling across the site

You can also use the `--recursive` option to automatically include subdirectories:

    mint publish my-garden . --recursive --destination public --template garden

## Configuration

Mint looks for configuration files in this order:

1. `./mint.yml` (local directory)
2. `~/.config/mint/config.yml` (user home)

Command-line options override configuration file settings.

## Template paths

Mint searches for templates in this order:

1. Current working directory
2. `${HOME}/.mint` 
3. Mint gem directory (global, built-in templates)
