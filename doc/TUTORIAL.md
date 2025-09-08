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

### Extract titles from filenames

Use the filename as the document title:

    mint publish my-article.md --file-title

This removes the `.md` extension from the filename and uses it as both the HTML title and an H1 heading.

### Preserve directory structure

Keep your source directory structure in the output:

    mint publish docs/**/*.md --destination public --preserve-structure

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

Mint can be configured using TOML configuration files that specify defaults for any command-line option. Configuration files are loaded in this order (later files override earlier ones):

1. **Global**: Built-in defaults
2. **User**: `~/.config/mint/config.toml`  
3. **Local**: `.mint/config.toml` (current directory)
4. **Command-line**: Explicit options (highest priority)

### Creating a config file

Create `.mint/config.toml` in your project directory:

```toml
# Use a specific template by default
template = "nord"

# Always publish to a build directory
destination = "public"

# Preserve source directory structure
preserve-structure = true

# Enable navigation for documentation sites
navigation = true
navigation-title = "My Documentation"
navigation-depth = 2

# Extract titles from filenames
file-title = true
```

Now when you run `mint publish docs/**/*.md`, it will automatically:

- Use the Nord template
- Output to the `public/` directory  
- Preserve the directory structure from `docs/`
- Generate navigation with your custom title
- Extract page titles from filenames

You can still override any config setting from the command line:

```bash
# Use a different destination despite config file
mint publish docs/**/*.md --destination staging

# Override boolean settings from config using --no- flags
mint publish docs/**/*.md --no-navigation --no-file-title

# Mix positive and negative overrides
mint publish docs/**/*.md --preserve-structure --no-navigation
```

### Overriding boolean config settings

For boolean options set to `true` in your config file, you can disable them using `--no-` flags:

- `--no-preserve-structure` - Don't preserve directory structure
- `--no-navigation` - Disable navigation panel  
- `--no-file-title` - Don't extract titles from filenames
- `--no-navigation-autodrop` - Disable automatic directory level dropping

This is particularly useful when you have defaults in your config file but want to selectively disable features for specific builds.

### Config file locations

You can place config files at different scopes:

- **`.mint/config.toml`** - Project-specific settings (highest priority)
- **`~/.config/mint/config.toml`** - User-wide defaults  
- Built-in defaults (lowest priority)

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
navigation-drop = 1
navigation-depth = 3
navigation-title = "Documentation"
file-title = true
```

## Navigation behavior

When navigation is enabled, Mint organizes your files into a navigable directory structure. By default, Mint uses **autodrop** to create cleaner navigation by automatically removing common directory levels.

### Autodrop (default behavior)

Autodrop removes directory levels that are common to all files, stopping when it reaches multiple top-level nodes. This creates more meaningful navigation:

```bash
# Example: All files under docs/content/
mint publish docs/content/guide/*.md docs/content/api/*.md --navigation

# Navigation shows:
#   guide/
#     getting-started.md
#     advanced.md  
#   api/
#     reference.md
# (docs/content/ is automatically dropped)
```

### Manual control

You can control navigation behavior with these options:

```bash
# Disable autodrop - show full directory structure
mint publish docs/**/*.md --no-navigation-autodrop --navigation

# Manual drop - remove exactly N levels (cannot be used with navigation-autodrop)
mint publish docs/**/*.md --navigation-drop 2 --navigation

# Limit navigation depth after dropping
mint publish docs/**/*.md --navigation-depth 2 --navigation
```

**Important**: `--navigation-autodrop` and `--navigation-drop` cannot be used together. Autodrop is enabled by default; use `--no-navigation-autodrop` if you want manual control.

## Template paths

Mint searches for templates in this order:

1. Current working directory
2. `${HOME}/.mint` 
3. Mint gem directory (global, built-in templates)
