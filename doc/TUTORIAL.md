# Mint tutorial

Mint is a publishing tool that converts plain text Markdown documents into beautifully formatted HTML files.

Mint lets you:

- Convert Markdown documents to styled HTML
- Publish digital gardens—collections of cross-linked Markdown files
- Apply consistent styling across all your documents
- Generate navigation for multi-page sites
- Work entirely offline

## Installation

Install Mint through Ruby:

    gem install mint

## Basic usage

Convert a Markdown file to HTML:

    mint publish Document.md

This creates `Document.html` in the current directory. It will be styled
with the default template, and its style will be inlined into the document,
making it portable as a standalone file.

### Using templates

Instead of the default template, you can choose a different template for automatic styling:

    mint publish Document.md --template nord

Mint has several built-in templates, and you can also create your own. (See
[TEMPLATES](./TEMPLATES.md) for more).

### Output directory

Specify where the output file goes:

    mint publish Document.md --destination final-draft

### Mix and match layouts and styles

Use different layouts and stylesheets:

    mint publish Document.md --layout default --style nord

### Insert title heading

Insert the document's title as an H1 heading into the content:

    mint publish Document.md --insert-title-heading

This extracts the title from metadata or filename and injects it as an H1 heading at the top of the document content.

### Flatten directory structure

Directory structure is preserved by default (except for directories dropped by
`--autodrop`). To flatten all files into the destination directory:

    mint publish docs/**/*.md --destination public --no-preserve-structure

Note that if there are multiple files with the same name, only one will be kept.
(Don't depend on the ordering of which one will be kept in the case of a collision.)

## Digital gardens

Convert multiple cross-linked Markdown files into a connected "digital garden":

    mint publish Garden/**/*.md --destination public --navigation --navigation-title "My Garden"

This publishes a set of documents with:

- Links between files preserved  
- A navigation sidebar correctly linking to all other pages
- Consistent styling across the site

By default, the style will be inlined into each page, but you can also choose
to create and link to one external stylesheet using `--style-mode external`.

## Configuration

Mint can be configured using TOML configuration files that specify defaults for any command-line option. Configuration files are loaded in this order (later files override earlier ones):

1. **Global**: Built-in defaults
2. **User**: `~/.config/mint/config.toml`  
3. **Local**: `.mint/config.toml` (current directory)

Commandline flags supersede any options from these configuration files.

### Creating a config file

Create `.mint/config.toml` in your project directory:

```toml
# Use a specific template by default
template = "nord"

# Always publish to a build directory
destination = "public"

# Preserve source directory structure (default: true)
preserve-structure = true

# Enable navigation for documentation sites
navigation = true
navigation-title = "My Documentation"
navigation-depth = 2

# Insert title as H1 heading
insert-title-heading = true
```

Now when you run `mint publish docs/**/*.md`, it will automatically:

- Use the Nord template
- Output to the `public/` directory  
- Preserve the directory structure from `docs/`
- Generate navigation with your custom title
- Insert page titles as H1 headings

You can still override any config setting from the command line:

```bash
# Use a different destination despite config file
mint publish docs/**/*.md --destination staging

# Override boolean settings from config using --no- flags
mint publish docs/**/*.md --no-navigation --no-insert-title-heading
```

### Overriding boolean config settings

For boolean options set to `true` in your config file, you can disable them using`--no-` flags:

- `--no-autodrop` - Disable automatic directory level dropping
- `--no-preserve-structure` - Don't preserve directory structure
- `--no-navigation` - Disable navigation panel  
- `--no-insert-title-heading` - Don't insert title as H1 heading

This is particularly useful when you have defaults in your config file but want to selectively
disable features for specific builds.

### Available config options

Any command-line option can be specified in the config file using the same name.

```toml
template = "nord"
layout = "custom"
style = "custom-dark"  
working-dir = "./path/to/docs"
output-file = "%{ext}.%{new_extension}"
destination = "build"
style-mode = "external"
style-destination = "assets/css"
preserve-structure = true
navigation = true
navigation-depth = 3
navigation-title = "Documentation"
insert-title-heading = true
```
