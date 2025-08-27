# Creating Mint templates

Create custom layouts and styles to control how your documents look when published.

## Template overview

Templates consist of two parts:

- **Layout**: The HTML structure (written in [ERB][] or [Haml][])  
- **Style**: The CSS styling (written in CSS, [Sass][], or [SCSS][])

Mint provides convenience methods and base stylesheets to ease template creation.

## Template structure

Templates are organized in directories under `templates/`:

```
templates/
├── my-template/
│   ├── layout.erb
│   └── style.scss
└── another-template/
    ├── layout.haml
    └── style.css
```

Templates work best when their layout and style are designed together, but users can mix and match them.

## Creating a layout

Layouts define the HTML structure around your content. Use template files (not raw HTML) so you can insert dynamic content.

### Essential methods

- `content` – Inserts the converted Markdown content
- `stylesheet_tag` – Includes the stylesheet (inline or linked)

### ERB example

```erb
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title><%= title %></title>
    <%= stylesheet_tag %>
  </head>
  <body>
    <article>
      <%= content %>
    </article>
  </body>
</html>
```

### Haml example

```haml
!!!
%html
  %head
    %meta(charset="utf-8")
    %title= title
    = stylesheet_tag
  %body
    %article= content
```

## Creating styles

Stylesheets control the visual appearance of your documents. Mint compiles Sass/SCSS automatically.

### CSS example

```css
body {
  font-family: Georgia, serif;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

h1, h2, h3 {
  color: #333;
  font-weight: normal;
}
```

### SCSS example

```scss
$primary-font: Georgia, serif;
$max-width: 800px;
$text-color: #333;

body {
  font-family: $primary-font;
  line-height: 1.6;
  max-width: $max-width;
  margin: 0 auto;
  padding: 2rem;
}

h1, h2, h3 {
  color: $text-color;
  font-weight: normal;
}
```

## Built-in templates

Mint includes several ready-to-use templates:

- **default** - Clean, minimal styling
- **nord** - Light theme inspired by Nord color palette
- **nord-dark** - Dark theme inspired by Nord color palette
- **garden** - For digital gardens with navigation

## Template variables

Available in layout templates:

- `content` – The converted document content
- `title` – Document title (from first heading or filename)
- `stylesheet_tag` – Proper stylesheet inclusion

## Testing templates

Test your templates during development:

```bash
# Test with a sample document
mint publish sample.md --template my-template --destination test/

# Use simulation mode to preview without creating files
mint publish sample.md --template my-template --simulation
```

## Best practices

- Keep layouts semantic and accessible
- Use relative units (em, rem) for better scalability  
- Test with various document lengths and structures
- Consider print styles for PDF output
- Follow a consistent naming convention
- Include fallback fonts in your CSS

## Template locations

Mint searches for templates in this order:

1. Current working directory
2. `${HOME}/.mint/templates/`
3. System templates directory
4. Built-in Mint templates

[ERB]: https://ruby-doc.org/stdlib-3.1.1/libdoc/erb/rdoc/ERB.html
[Haml]: https://haml.info
[Sass]: https://sass-lang.com/
[SCSS]: https://sass-lang.com/