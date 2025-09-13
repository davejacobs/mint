# Mint API

Use Mint programmatically in your Ruby applications to convert Markdown documents to styled HTML.

## Quick start

```ruby
require 'mint'

Mint.publish! "document.md"
```

This creates `document.html` with default styling.

## Configuration options

Mint accepts configuration as a `config:` keyword argument that can be a Hash or Config object:

```ruby
# Using a Hash
Mint.publish! "document.md", 
  config: {
    layout_name: "professional",
    style_name: "professional",
    insert_title_heading: true
  }

# Using a Config object
config = Mint::Config.new(
  layout_name: "professional", 
  style_name: "professional"
)
Mint.publish! "document.md", config: config
```

### Template options

Specify layout and style together using a template:

```ruby
Mint.publish! "document.md", config: { template_name: "professional" }
```

Or specify layout and style separately:

```ruby
Mint.publish! "document.md", 
  config: {
    layout_name: "article", 
    style_name: "serif"
  }
```

### Destination options

Control where files are written:

```ruby
Mint.publish! "document.md",
  config: {
    destination_directory: Pathname.new("output"),
    style_destination_directory: "styles",
    preserve_structure: true
  }
```

### Style modes

Control how styles are included:

```ruby
# Inline styles (default)
Mint.publish! "document.md", config: { style_mode: :inline }

# External stylesheets
Mint.publish! "document.md", config: { style_mode: :external }

# Link to original CSS files (for development)
Mint.publish! "document.md", config: { style_mode: :original }
```

## Available configuration options

- `:layout_name` – Layout template name
- `:style_name` – Style template name  
- `:destination_directory` – Output directory for HTML files
- `:style_destination_directory` – Directory for stylesheets
- `:style_mode` – How styles are included (`:inline`, `:external`, `:original`)
- `:output_file_format` – Custom filename format with substitutions
- `:working_directory` – Root directory for relative paths
- `:insert_title_heading` – Insert document title as H1 heading into content (default: false)
- `:preserve_structure` – Preserve source directory structure (default: true)
- `:navigation` – Enable navigation panel (default: false)
- `:navigation_title` – Title for navigation panel
- `:navigation_depth` – Maximum depth to show in navigation (default: 3)
- `:autodrop` – Automatically drop common directory levels from output paths (default: true)

## Publishing multiple files

```ruby
# Use Mint::Commandline.publish! for multiple files
files = [Pathname.new("intro.md"), Pathname.new("guide.md"), Pathname.new("reference.md")]
Mint::Commandline.publish!(files, config: {
  template_name: "professional",
  destination_directory: Pathname.new("public"),
  navigation: true,
  navigation_title: "Documentation"
})
```

**Note:** When working with file paths programmatically, use `Pathname` objects instead of strings for proper path handling and cross-platform compatibility.

### Working with Workspace directly

For more control over the publishing process:

```ruby
require 'mint/workspace'

files = [Pathname.new("intro.md"), Pathname.new("guide.md")]
config = Mint::Config.new(
  destination_directory: Pathname.new("public"),
  navigation: true,
  navigation_title: "Docs"
)

workspace = Mint::Workspace.new(files, config)
destination_paths = workspace.publish!

# destination_paths contains the relative paths where files were written
destination_paths.each { |path| puts "Created: #{path}" }
```

## Template variables

Templates have access to the following variables:

- `content` – Rendered HTML content from the Markdown
- `stylesheet_tag` – Generated style tag (`<style>` or `<link>`) 
- `metadata` – YAML frontmatter from the Markdown file
- `files` – Navigation tree data (when `navigation: true`)
- `title` – Extracted or generated title
- `inject_title` – Boolean indicating if title should be inserted as H1 heading
- `show_navigation` – Boolean indicating if navigation should be shown
- `navigation_title` – Title for the navigation panel
- `current_path` – Path to current source file
- `working_directory` – Current working directory

### Navigation data structure

When `navigation: true` is enabled, the `files` variable contains an array of navigation items:

```ruby
[
  {
    title: "Introduction",           # Display title
    html_path: "intro.html",        # Path to HTML file (nil for directories)
    source_path: "intro.md",        # Original source file path
    depth: 0                        # Nesting level
  },
  {
    title: "API Reference", 
    html_path: nil,                 # Directory entries have no html_path
    source_path: nil,               # Directory entries have no source_path
    depth: 0,
    is_directory: true              # Indicates this is a directory
  },
  {
    title: "Classes",
    html_path: "api/classes.html",
    source_path: "api/classes.md", 
    depth: 1                        # Nested under "API Reference"
  }
]
```

## Path handling

Mint handles paths carefully to ensure cross-platform compatibility:

### Input files
- File paths are kept as relative paths until resolution time
- Use `Pathname` objects when working programmatically for best results
- Absolute paths are converted to relative where possible

### Output destinations
- Destination paths are resolved at publish time by combining `destination_directory` + relative output path
- The `preserve_structure` feature (enabled by default) maintains the original directory structure
- The `autodrop` feature (also enabled by default) removes common directory prefixes when structure is not preserved

### Example path transformations

With `preserve_structure: true` (default):
```
Input files:       docs/api/intro.md, docs/api/classes.md, docs/guide.md
Output:           docs/api/intro.html, docs/api/classes.html, docs/guide.html
```

With `preserve_structure: false` and `autodrop: true`:
```
Input files:       docs/api/intro.md, docs/api/classes.md, docs/guide.md
Common prefix:     docs/ (dropped)
Output:           api/intro.html, api/classes.html, guide.html
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