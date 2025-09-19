# Mint

Transform your plain text documents into beautiful HTML documents with customizable styling and templates.

![Status](https://github.com/davejacobs/mint/actions/workflows/build.yml/badge.svg)

## Why Mint?

- **Focus on writing** – Keep documents as plain text
- **Beautiful output** – Professional-looking HTML ready for print or web
- **Digital gardens** – Easily publish linked sets of HTML documents from tools like Obsidian
- **Version control-friendly** – Text documents work great with Git
- **Scriptable** – Automate document processing and analysis
- **Highly customizable** – Create your own templates and styles

## Installation

```bash
gem install mint
```

## Documentation

- **Complete usage guide:** [TUTORIAL.md](doc/TUTORIAL.md)
- **Man page:** `man mint`
- **API documentation:** [RubyDoc](http://www.rubydoc.info/gems/mint)

## Get started

Transform a Markdown document into styled HTML:

```bash
mint Document.md
```

This creates `Document.html` in your current directory with beautiful default styling. The styles
are inlined by default, so you can send your document to anyone you'd like, and they'll see the
same thing.

## Usage

### Basic commands

```bash
# Publish a single document with a default template
mint Document.md

# Publish with a non-default template
mint Document.md --template nord

# Publish to the public directory
mint Document.md --destination public

# Publish multiple files, specifying them using a glob pattern
mint *.md --destination final-drafts

# Read Markdown content piped from STDIN and print the resulting HTML and CSS
# to STDOUT; note that this is limited to a single file
echo "# Document" | mint - --output-file -

# Publish multiple files and generate a left-hand navigation panel in the default
# template using a template-specific option. Shell globs allow you to recursively include
# nested files. Note that by default nested directories structure be preserved in the output,
# but any directories common to all files (in this case, `content`), will be automatically removed
# from the output ("autodropped") for convenience.
mint content/**/*.md --destination public --opt navigation --opt navigation-title "Documentation"

# Publish nested files without preserving structure
mint content/**/*.md --destination public --no-preserve-structure
```

### Common options

| Flag | Description |
|------|-------------|
| `-t, --template TEMPLATE` | Use a built-in template (combines layout + style) |
| `-l, --layout LAYOUT` | Specify only the template layout, by name |
| `-s, --style STYLE` | Specify only the template style, by name |
| `-m, --style-mode MODE` | How styles are included (inline, external, original) |
| `-d, --destination DIR` | Output directory |
| `-o, --output-file FORMAT` | Custom output filename, with substitutions available, or `-` for STDOUT |
| `--opt OPT[=VAL]` | Specify template-specific options, e.g., --opt navigation for the default template |
| `--no-preserve-structure` | Flatten all published files into one directory rather than preserving structure |
| `--no-autodrop` | Do not automatically drop common parent directories from published files |
| `-v, --verbose` | Show where documents were published |

### Built-in templates

- `default` – Clean layout with serif font
- `nord` – Modern layout with sans-serif font; uses Nord color scheme and sans text
- `nord-dark` – Dark version of Nord

### Custom templates

It's easy to write a custom template: simply create a directory in `~/.config/mint/templates` or `./mint/templates`
with the name of your new template. Create a `style.css` file and an optional `layout.html` file (which uses ERB
to include variables like the document title and body). If you opt not to create a new `layout.html`, the 
layout from the default template will be used.

Mint layouts are written in ERB-flavored HTML, and stylesheets are written in CSS.

## Configuration

Mint can be configured using TOML configuration files that specify defaults for commandline options.
Configuration options are loaded in the following order (later files override earlier ones):

1. **Global**: Built-in defaults
2. **User**: `~/.config/mint/config.toml`  
3. **Local**: `.mint/config.toml`
4. **Commandline**: Explicit flags override any other configuration

### Example configuration file

Create `.mint/config.toml` in your project directory:

```toml
# Template and styling
template = "nord"

# File output handling
destination = "public"
preserve-structure = false
output-file = "%{basename}_processed.%{new_extension}"
style-mode = "external"

[options]                          # These are options for the default layout
navigation = true
navigation-title = "Documents"
navigation-depth = 3               # Maximum depth for items in navigation sidebar
insert-title-heading = true        # Add the document title as an <h1> above document content
```

### Overriding configuration file settings

For most flags, overriding the configuration file is simple: Simply
specify a new value via commandline flags. Boolean flags require a slightly
different approach: use the `--no-[option]` variant of the relevant flag.

For example, if you've set the layout option `preserve-structure = true` in `config.toml`,
you can override that at the commandline:

```bash
mint docs.md --no-preserve-structure
```

You can do the same with layout options via `--opt no-*` variants of your template's
specific options.

### Style modes

Mint offers three ways to include styles in your HTML output:

- `inline` (default) – CSS is embedded directly in the HTML document as `<style>` tags
- `external` – CSS is compiled into a single external file in your destination directory and is
  automatically linked from your document with `<link>` tags
- `original` – Links directly to original CSS template files without processing

The `original` mode is particularly useful for template development, as it allows you to edit CSS
files and see changes immediately without republishing. In this mode, `@import` statements in CSS
files will be included as additional `<link>` tags.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the tests: `rspec`
5. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.