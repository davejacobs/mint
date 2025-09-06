# Mint Ruby API

Use Mint programmatically in your Ruby applications to convert Markdown documents to styled HTML.

## Quick start

```ruby
require 'mint'

Mint.publish! "document.md"
```

This creates `document.html` with default styling.

## Configuration options

Mint accepts configuration as keyword arguments for clean, readable code:

```ruby
require 'mint'

Mint.publish! "document.md", 
  layout_name: "professional",
  style_name: "professional",
  file_title: true
```

You can also pass a `Config` object if preferred:

```ruby
config = Mint::Config.new(
  layout_name: "professional", 
  style_name: "professional"
)

Mint.publish! "document.md", config
```

### Template options

Specify layout and style together using a template:

```ruby
Mint.publish! "document.md", template_name: "professional"
```

Or specify layout and style separately:

```ruby
Mint.publish! "document.md", 
  layout_name: "article", 
  style_name: "serif"
```

### Destination options

Control where files are written:

```ruby
Mint.publish! "document.md",
  destination_directory: Pathname.new("output"),
  style_destination_directory: "styles",
  preserve_structure: true
```

### Style modes

Control how styles are included:

```ruby
# Inline styles (default)
Mint.publish! "document.md", style_mode: :inline

# External stylesheets
Mint.publish! "document.md", style_mode: :external

# Link to original CSS files (for development)
Mint.publish! "document.md", style_mode: :original
```

## Available configuration options

- `:layout_name` – Layout template name
- `:style_name` – Style template name  
- `:destination_directory` – Output directory for HTML files
- `:style_destination_directory` – Directory for stylesheets
- `:style_mode` – How styles are included (`:inline`, `:external`, `:original`)
- `:output_file_format` – Custom filename format with substitutions
- `:preserve_structure` – Preserve source directory structure
- `:working_directory` – Root directory for relative paths
- `:navigation` – Enable navigation panel (default: false)
- `:navigation_title` – Title for navigation panel
- `:navigation_drop` – Drop first N directory levels from navigation (default: 0)
- `:navigation_depth` – Maximum depth to show in navigation (default: 3)
- `:file_title` – Extract title from filename (removes .md extension) and inject into template (default: false)

## Publishing multiple files

```ruby
files = ["intro.md", "guide.md", "reference.md"]
files.each_with_index do |file, idx|
  # Only render style on first file to avoid duplicates
  Mint.publish! file,
    template_name: "professional",
    destination_directory: Pathname.new("public"),
    render_style: (idx == 0)
end
```

## Template variables

Pass custom variables to templates:

```ruby
files_data = [
  { title: "Introduction", html_path: "intro.html" },
  { title: "Guide", html_path: "guide.html" }
]

Mint.publish! "document.md", 
  navigation: true,
  navigation_title: "Documentation",
  variables: { files: files_data }
```

## Built-in templates

Available templates:
- `default` – Clean, centered layout
- `basic` – Minimal styling
- `nord` – Nord color scheme
- `nord-dark` – Dark Nord theme

## Template resolution

When you specify a template name, Mint searches:

1. Current working directory
2. `~/.config/mint/templates/`  
3. Built-in Mint templates

File paths are resolved relative to the current working directory.