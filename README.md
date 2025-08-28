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

# Publish a digital garden, with linked navigation
mint publish content/**/*.md --template garden --destination public
```

### Common Options

| Flag | Description |
|------|-------------|
| `-t, --template TEMPLATE` | Use a built-in template (combines layout + style) |
| `-l, --layout LAYOUT` | Specify only the layout |
| `-s, --style STYLE` | Specify only the style |
| `-d, --destination DIR` | Output directory |
| `-o, --output-file FORMAT` | Custom output filename format |
| `--style-destination PATH` | Create external stylesheet and link it (rather than default of inlining style) |
| `-r, --recursive` | Find all Markdown files in any directories specified |

### Built-in Templates

- `default` – Clean, minimal styling
- `nord` – Clean, uses Nord color scheme
- `nord-dark` – Dark version of Nord
- `garden` – For digital gardens; includes navigation

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

## Templates and customization

Mint supports layouts written in HAML or ERB and stylesheets can be written in CSS, SCSS, or SASS.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the tests: `rspec`
5. Submit a pull request

## License

MIT License. See [LICENSE](LICENSE) for details.