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

Set defaults to avoid repeating command-line options.

### Configuration files

Mint looks for config files in this order:

1. `./mint.yml` (local directory)
2. `~/.config/mint/config.yml` (user home)

### Setting defaults

Set a default template for the current directory:

    mint set template=serif-professional

Set user-wide defaults:

    mint set --user template=professional  

Set system-wide defaults:

    mint set --global template=normal

### Configuration hierarchy

More specific settings override general ones:

1. Command-line options (highest priority)
2. Local config file
3. User config file
4. Global config file (lowest priority)

### View active settings

See what configuration is currently active:

    mint config

### Command options

- `--verbose, -v` – show detailed output
- `--simulation, -s` – preview changes without executing

### Editing templates

Edit templates directly from the command line:

    mint edit --layout my-layout
    mint edit --style my-style

Mint opens the file in your `$EDITOR`. Short forms work too:

    mint edit -l normal
    mint edit -s normal

## Template paths

Mint searches for templates in this order:

1. Current working directory
2. `${HOME}/.mint` 
3. Mint gem directory (global, built-in templates)
