# Mint

Transform your plain text documents into beautiful HTML documents with customizable styling and templates.

## Installation

```bash
gem install mint
```

## Quick Start

Transform a Markdown document into styled HTML:

```bash
mint publish Document.md
```

This creates `Document.html` in your current directory with beautiful default styling.

## Usage

### Basic Commands

```bash
# Publish a single document
mint publish Document.md

# Publish with a template
mint publish Document.md --template nord

# Publish to a specific directory
mint publish Document.md --destination public

# Publish multiple files
mint publish *.md --destination final-drafts

# Publish with navigation panel
mint publish content/**/*.md --navigation --navigation-title "My Documentation" --destination public

# Extract titles from filenames
mint publish my-document.md --file-title
```

### Common Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help message |
| `-t, --template TEMPLATE` | Use a built-in template (combines layout + style) |
| `-l, --layout LAYOUT` | Specify only the layout |
| `-s, --style STYLE` | Specify only the style |
| `-w, --working-dir WORKING_DIR` | Specify a working directory outside the current directory |
| `-d, --destination DIR` | Output directory |
| `-o, --output-file FORMAT` | Custom output filename format with substitutions |
| `-m, --style-mode MODE` | How styles are included (inline, external, original) |
| `--style-destination PATH` | Create external stylesheet and link it (sets mode to external) |
| `--preserve-structure` | Preserve source directory structure (e.g., nesting) in destination |
| `-r, --recursive` | Find all Markdown files in any directories specified |
| `--navigation` | Enable navigation panel showing all files |
| `--navigation-title TITLE` | Set title for navigation panel |
| `--navigation-drop LEVELS` | Drop first N directory levels from navigation |
| `--navigation-depth DEPTH` | Maximum depth to show in navigation (default: 3) |
| `--file-title` | Extract title from filename (removes .md extension) and inject into template |

### Style modes

Mint offers three ways to include styles in your HTML output:

- **`inline`** (default) – CSS is embedded directly in the HTML document as `<style>` tags
- **`external`** – CSS is compiled and saved as separate files, linked with `<link>` tags
- **`original`** – Links directly to original CSS template files without processing (for live editing)

The `original` mode is particularly useful for template development, as it allows you to edit CSS files and see changes immediately without republishing. Only `.css` files are supported in this mode, and `@import` statements in CSS files will be included as additional `<link>` tags.

### Built-in templates

- `default` – Clean, centered, modern layout
- `basic` – Clean, minimal styling, focuses on text
- `nord` – Clean, uses Nord color scheme and sans text
- `nord-dark` – Dark version of Nord

### Custom templates

It's easy to write a custom template: simply create a directory in `~/.config/mint/templates` or `./mint/templates`
with the name of your new template. Create a `style.css` file and an optional `layout.html` file (which uses ERB
to include variables like the document title and body). If you opt not to create a new `layout.html`, the 
layout from the default template will be used.

Mint layouts are written in ERB-flavored HTML, and stylesheets are written in CSS.

## Documentation

- **Complete usage guide:** [TUTORIAL.md](doc/TUTORIAL.md)
- **Man page:** `man mint` (after installation)
- **API documentation:** [RubyDoc](http://www.rubydoc.info/github/davejacobs/mint)

## Why Mint?

- **Focus on writing** – Keep documents as plain text
- **Version control friendly** – Text files work great with Git
- **Scriptable** – Automate document processing
- **Beautiful output** – Professional-looking HTML ready for print or web
- **Highly customizable** – Create your own templates and styles

## Configuration

Mint can be configured using TOML configuration files that specify defaults for commandline options.
Configuration options are loaded in the following order (later files override earlier ones):

1. **Global**: Built-in defaults
2. **User**: `~/.config/mint/config.toml`  
3. **Local**: `.mint/config.toml` (current directory)
4. **Commandline**: Explicit flags override any other configuration

### Example config file

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

### Overriding config file settings

You can override boolean settings from config files using `--no-` flags:

```bash
# If your config.toml has navigation = true and file-title = true
mint publish docs.md --no-navigation --no-file-title

# Mix positive and negative flags
mint publish docs.md --preserve-structure --no-navigation
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