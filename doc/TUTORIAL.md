# Mint tutorial

Mint is a publishing tool that converts plain text Markdown documents into beautifully
formatted HTML files.

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

    mint Document.md

This creates `Document.html` in the current directory. It will be styled with the default template,
and its style will be inlined into the document, making it portable as a standalone file.

### Using templates

Instead of the default template, you can choose a different template for automatic styling:

    mint Document.md --template nord

Mint has several built-in templates, and you can also create your own. (See
[TEMPLATES](./TEMPLATES.md) for more).

### Output directory

Specify where the output file goes:

    mint Document.md --destination final-draft

### Mix and match layouts and styles

Use different layouts and stylesheets:

    mint Document.md --layout default --style nord

### Insert title heading

Insert the document's title as an H1 heading into the content:

    mint Document.md --opt insert-title-heading

Note: This is a layout-specific option and only works if your specified layout supports it.

## Autodrop

By default, Mint "autodrops" any parent directories that are common to all files that you pass
in. This makes globbing convenient:

    mint docs/**/*.md --destination public

In this case, if you had a `docs/Document.md` file, then it would be output to `public/Document.html` rather than `public/docs/Document.html`.

This default can be overridden with the --no-autodrop setting.

### Flatten directory structure

Directory structure is preserved by default when you pass files into Mint. For example, if you
have `docs/subsection-1/Document.md`, then you'll end up with `docs/subsection-1/Document.html`
in your destination directory.

To flatten all files directly into the destination directory, ignoring any directory structure:

    mint docs/**/*.md --destination public --no-preserve-structure

*Warning*: If there are multiple files with the same name, only one will be kept.
(Don't depend on the ordering of which one will be kept in the case of a collision.)

## Digital gardens

You can publish multiple cross-linked Markdown files as a connected "digital garden":

    mint Garden/**/*.md --destination public --opt navigation --opt navigation-title="My Garden"

This publishes a set of documents with:

- Links between files preserved  
- A navigation sidebar correctly linking to all other pages
- Consistent styling across all pages

By default, the style will be inlined into each page, but you can also choose to create and link
to one external stylesheet using `--style-mode external` for efficiency.

## Configuration

Mint can be configured using TOML configuration files that specify defaults for any commandline
option. Configuration files are loaded in this order (later files override earlier ones):

1. **Global**: Built-in defaults from Gem root
2. **User**: `~/.config/mint/config.toml`  
3. **Local**: `.mint/config.toml` (current directory)

Commandline flags supersede any options from these configuration files.

### Example: Creating a local config file

Create `.mint/config.toml` in your project directory:

```toml
# Use a specific template by default
template = "nord"

# Always publish to the public directory
destination = "public"

# Preserve source directory structure (default: true)
preserve-structure = false

# The following are template-specific options which apply to the default layout and any templates
# that use it (i.e., templates which don't specify their own layout.erb)
[options]
# Enable navigation for documentation sites
navigation = true
navigation-title = "My Documentation"
navigation-depth = 2

# Insert title as H1 heading
insert-title-heading = true
```

Now when you run `mint docs/**/*.md`, it will automatically:

- Use the Nord template
- Output to the `public/` directory  
- Preserve the directory structure from `docs/`
- Generate navigation with your custom title
- Insert page titles as H1 headings

You can still override any config setting from the commandline:

```bash
# Use a different destination despite config file
mint docs/**/*.md --destination staging

# Override boolean settings from config using --no- flags
mint docs/**/*.md --no-navigation --no-insert-title-heading
```

### Overriding boolean config settings

While most config-file options can be overridden easily at the commandline, boolean values
use a special syntax if you'd like to negate them. You appende `--no-` to the name of the option,
and that flag will negate the option. For example:

- `--no-autodrop` - Disable automatic directory level dropping
- `--no-preserve-structure` - Don't preserve directory structure
- `--opt no-navigation` - Disable navigation panel  
- `--opt no-insert-title-heading` - Don't insert title as H1 heading

### Available config options

Any command-line option can be specified in the config file using the same name.

```toml
template = "nord"
layout = "custom"
style = "custom-dark"  
output-file = "%{ext}.%{new_extension}"
destination = "build"
style-mode = "external"
style-destination = "assets/css"
preserve-structure = true

[options]
navigation = true
navigation-depth = 3
navigation-title = "Documentation"
insert-title-heading = true
```
