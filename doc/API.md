# Mint Ruby API

Use Mint programmatically in your Ruby applications to convert Markdown documents to styled HTML.

## Quick start

```ruby
require 'mint'

document = Mint::Document.new "document.md"
document.publish!
```

This creates `document.html` with default styling.

## Document options

### Template options

Specify layout and style together:

```ruby
document = Mint::Document.new "document.md", template: "professional"
```

Or specify layout and style separately:

```ruby
document = Mint::Document.new "document.md", 
  layout: "article", 
  style: "serif"
```

**Default**: `template: "default"`

### Destination options

Control where files are written:

```ruby
document = Mint::Document.new "document.md",
  destination: "output",
  style_destination: "styles"
```

- `:destination` – Output directory for HTML files
- `:style_destination` – Subdirectory for stylesheets (relative to destination)

**Defaults**: Both are `nil` (files written to current directory)

## Document methods

### Publishing

```ruby
document = Mint::Document.new "document.md"
document.publish!  # Creates the HTML file
```

### Configuration

Set options after creation:

```ruby
document = Mint::Document.new "document.md"
document.template = "professional"
document.destination = "output"
document.publish!
```

## Block initialization

Configure documents with a block:

```ruby
document = Mint::Document.new "document.md" do |doc|
  doc.template = "resume"
  doc.destination = "portfolio"
end

document.publish!
```

Block configuration happens after default values are set, so you only need to specify what you want to change.

## Style objects

Create style objects directly:

```ruby
# From template name
style = Mint::Style.new "professional"

# From file path  
style = Mint::Style.new "path/to/custom.css"

# With destination
style = Mint::Style.new "custom.scss", destination: "styles"
```

## Complete example

```ruby
require 'mint'

# Simple usage
Mint::Document.new("readme.md").publish!

# With options
Mint::Document.new "article.md", 
  template: "professional",
  destination: "public" do |doc|
  doc.publish!
end

# Multiple documents
%w[intro.md guide.md reference.md].each do |file|
  Mint::Document.new(file, template: "docs").publish!
end
```

## Template resolution

When you specify a template name, Mint searches:

1. Current working directory
2. `${HOME}/.mint/templates/`  
3. System templates directory
4. Built-in Mint templates

File paths are resolved relative to the current working directory.