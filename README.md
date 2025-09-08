# Mint

Transform your plain text documents into beautiful HTML documents with customizable styling and templates.

![Status](https://github.com/davejacobs/mint/actions/workflows/build.yml/badge.svg)

## Why Mint?

- **Focus on writing** – Keep documents as plain text
- **Beautiful output** – Professional-looking HTML ready for print or web
- **Digital gardnes** – Easily publish linked sets of HTML documents from tools like Obsidian
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
- **API documentation:** [RubyDoc](http://www.rubydoc.info/github/davejacobs/mint)

## Get started

Transform a Markdown document into styled HTML:

```bash
mint publish Document.md
```

This creates `Document.html` in your current directory with beautiful default styling. The styles
are inlined by default, so you can send your document to anyone you'd like, and they'll see the
same thing.

## Usage

### Basic commands

```bash
# Publish a single document
mint publish Document.md

# Publish with a template
mint publish Document.md --template nord

# Publish to a specific directory
mint publish Document.md --destination public

# Publish multiple files
mint publish *.md --destination final-drafts

# Read Markdown content piped from STDIN using `-`, limited to a single file
echo "# Document" | mint publish - --output-file Document.html

# Publish with navigation panel; use globs to recursively include nested files
mint publish content/**/*.md --preserve-structure --navigation --navigation-title "Documentation" --destination public

# Guess document title (and h1 header) from filename
mint publish Document.md --file-title
```

### Common options

| Flag | Description |
|------|-------------|
| `-t, --template TEMPLATE` | Use a built-in template (combines layout + style) |
| `-l, --layout LAYOUT` | Specify only the template layout, by name |
| `-s, --style STYLE` | Specify only the template style, by name |
| `-m, --style-mode MODE` | How styles are included (inline, external, original) |
| `-o, --output-file FORMAT` | Custom output filename, with substitutions available |
| `-d, --destination DIR` | Output directory |
| `--file-title` | Extract title from filename and inject into template |
| `--preserve-structure` | Preserve source directory structure (e.g., nesting) in destination |
| `--navigation` | Enable navigation panel showing all files |
| `--navigation-title TITLE` | Set title for navigation panel |
| `-v, --verbose` | Show information about document processing |

### Style modes

Mint offers three ways to include styles in your HTML output:

- `inline` (default) – CSS is embedded directly in the HTML document as `<style>` tags
- `external` – CSS is compiled and saved as separate files, linked with `<link>` tags
- `original` – Links directly to original CSS template files without processing (for live editing)

The `original` mode is particularly useful for template development, as it allows you to edit CSS files and see changes immediately without republishing. Only `.css` files are supported in this mode, and `@import` statements in CSS files will be included as additional `<link>` tags.

### Built-in templates

- `default` – Clean, centered, modern layout
- `basic` – Clean, minimal styling, focuses on text
- `nord` – Clean, uses Nord color scheme and sans text
- `nord-dark` – Dark version of Nord
- `magazine` – Refined & easy to adapt for publications

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
preserve-structure = true
output-file = "%{basename}_processed.%{new_extension}"
style-mode = "external"

# Navigation
navigation = true
navigation-title = "My Docs"
navigation-depth = 3
navigation-drop = 1

# Other options
file-title = true
working-dir = "/path/to/source"
```

### Overriding configuration file settings

For most flags, overriding your configuration file is simple: You can simply
specify a new value via commandline flags. Boolean flags require a slightly
different approach, the use of `--no-[option]` flags.

If you've set `navigation = true` in `config.toml`, you can override that
at the commandline:

```bash
mint publish docs.md --no-navigation
```

Available `--no-` flags:
- `--no-preserve-structure` - Don't preserve directory structure 
- `--no-navigation` - Disable navigation panel
- `--no-file-title` - Don't extract titles from filenames

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the tests: `rspec`
5. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.