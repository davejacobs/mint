# Creating Mint templates

Create custom layouts and styles to control how your documents look when published.

## Template overview

Templates consist of two parts:

- **Layout**: The HTML structure (interpolating context variables using [ERB][])
- **Style**: The CSS styling

Mint provides convenience methods and base stylesheets to ease template creation.

## Template structure

Templates are organized in directories under `templates/`:

```
templates/
├── my-template/
│   ├── layout.html
│   └── style.css
└── another-template/
    ├── layout.html
    └── style.css
```

Templates work best when their layout and style are designed together,
but users can mix and match them. Custom templates that have only a style
file will use the `layout.html` from Mint's `default` template.

## Creating a layout

Layouts define the HTML structure around your content. Use template files
(not raw HTML) so you can insert dynamic content.

### Essential methods

- `content` – Inserts the converted Markdown content
- `stylesheet_tag` – Includes the stylesheet (inline or linked)
- `render` – Renders partials (see **Partials** section below)
- `javascript_tag` – Includes JavaScript files from the template directory

### Layout example

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

### Style example

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

## Partials

Layouts can be broken into reusable partials for better organization and maintainability. Partials are ERB templates that can be rendered from layouts or other partials.

### Using partials

Use the `render` method to include a partial:

```erb
<%= render 'navigation' %>
<%= render 'footer', year: 2024 %>
```

Partial files start with an underscore (`_`) and are resolved relative to the layout file:

```
templates/my-template/
├── layout.erb
├── _navigation.erb
├── _navigation_list.erb
└── _footer.erb
```

### Passing variables to partials

You can pass additional variables to partials as locals:

```erb
<%= render 'footer', year: 2024, company: "My Company" %>
```

All variables from the main layout are automatically available in partials.

### Recursive partials

Partials can render other partials, enabling complex nested structures like hierarchical navigation:

```erb
<!-- _navigation.erb -->
<nav>
  <ul>
    <% files.each do |item| %>
      <% if item[:is_directory] %>
        <li class="directory">
          <span><%= item[:title] %></span>
          <% if item[:children]&.any? %>
            <%= render 'navigation_list', files: item[:children] %>
          <% end %>
        </li>
      <% else %>
        <li><a href="<%= item[:html_path] %>"><%= item[:title] %></a></li>
      <% end %>
    <% end %>
  </ul>
</nav>
```

## JavaScript

Partials can include specific JavaScript files from their directory using the `javascript_tag` helper. This allows for modular, component-specific JavaScript functionality.

### Including JavaScript

Use `javascript_tag` to include JavaScript files:

```erb
<!-- In a partial -->
<div class="interactive-component">
  <!-- HTML content -->
</div>
<%= javascript_tag 'component.js' %>
```

JavaScript files are resolved relative to the partial's directory:

```
templates/my-template/
├── layout.erb
├── _navigation.erb
├── navigation.js          # JavaScript for navigation partial
├── _modal.erb
└── modal.js              # JavaScript for modal partial
```

### JavaScript file example

```javascript
// navigation.js
document.addEventListener('DOMContentLoaded', function() {
  // Toggle directory visibility
  document.querySelectorAll('.directory .directory-name').forEach(function(dirName) {
    dirName.addEventListener('click', function() {
      const parentLi = this.closest('li');
      const nestedUl = parentLi.querySelector('ul');
      if (nestedUl) {
        nestedUl.style.display = nestedUl.style.display === 'none' ? 'block' : 'none';
        parentLi.classList.toggle('collapsed');
      }
    });
  });
});
```

### Error handling

If a JavaScript file is not found, a HTML comment is inserted instead:

```html
<!-- JavaScript file not found: /path/to/missing.js -->
```

## Layout options

A templates can make use of user-specified layout options which are specific to that template. 
These options are passed in by the user and may be used to specify that a user wants to see,
for example, a navigation bar or breadcrumbs in the template layout.

Layout options are passed by the user from the commandline or configuration files, as with 
other options. They made available to templates as a hash.

### Using layout options

Pass boolean layout options using the `--opt` flag:

```bash
mint document.md --opt breadcrumbs --opt sidebar --opt toc
```

Use `no-` prefix to negate boolean options:

```bash
mint document.md --opt no-navigation --opt no-insert-title-heading
```

Pass key/value layout options using the `--opt` flag and the `=` sign:

```bash
mint document.md --opt navigation-depth=3
```

Negated options cannot be combined with value assignment. Use `--opt no-key` (not `--opt no-key=value`).

Layout options can also be specified by users in a config file in the \[options\] section:

```toml
# .mint/config.toml
[options]
breadcrumbs = true
sidebar = true
toc = true
# Set options to false directly, rather than with CLI-based no-* options
navigation = false
insert-title-heading = false
```

Access options in templates via the `options` hash:

```erb
<% if options[:breadcrumbs] %>
  <nav class="breadcrumbs">
    <a href="/">Home</a> > <a href="/docs/">Docs</a> > <%= title %>
  </nav>
<% end %>

<div class="<%= options[:sidebar] ? 'with-sidebar' : 'full-width' %>">
  <%= content %>
</div>

<% if options[:toc] %>
  <%= render 'table_of_contents' %>
<% end %>
```

**Note**: Option names with hyphens are automatically converted to underscores in the options hash. For example:
- `--opt navigation-title="Nav"` becomes `options[:navigation_title]`
- `--opt insert-title-heading` becomes `options[:insert_title_heading]`
- Config file `navigation-depth = 3` becomes `options[:navigation_depth]`

It is the template's responsibility to decide what default values are if an option isn't specified
by the user.

### Negated option behavior

- `--opt no-key` sets `options[:key] = false`
- Negation is case-sensitive: only lowercase `no-` prefix is recognized
- Option names starting with "no" work normally: `--opt notifications` and `--opt no-notifications` both affect the `notifications` option
- Double negation is not allowed: `--opt no-no-key` raises an error
- Later options override earlier ones: `--opt key --opt no-key` results in `false`
- Hyphens are converted to underscores: `--opt no-insert-title-heading` becomes `options[:insert_title_heading] = false`

## Built-in templates

Mint includes [ready-to-use templates][built-in templates], which can be consulted as a reference.

## Template variables

Mint makes these variables available in layout templates:

### Core content variables
- `content` – The converted document content (HTML)
- `title` – Document title (from first heading or filename)
- `stylesheet_tag` – HTML stylesheet tag (inline styles or external link)
- `working_directory` – Path to the project root
- `current_path` – Path to current source file
- `metadata` – Frontmatter metadata from the document

### Options hash

- `options` – Hash of all options passed via `--opt` flags or config file (hyphens converted to underscores)

## Testing templates

Test your templates during development:

```bash
mint Sample.md --template my-template --destination test --style-mode original
```

`--style-mode original` lets you easily update your CSS, even if it links
to other CSS, and refresh your `Sample.html` without a fresh `publish` command.

## Best practices

- Review built-in templates to understand the provided CSS variables,
  which can significantly reduce the work you need to do
- Test with various document lengths and structures; several auto-generated
  examples are provided in this repository
- Don't forget about print styles!

## Template locations

Mint searches for templates in this order:

1. `./mint/templates`
2. `${HOME}/.mint/templates/`
4. Built-in Mint templates (location is packaging dependent, but should be
   available from Gem installation path)

[built-in templates]: https://github.com/davejacobs/mint/tree/master/config/templates
[ERB]: https://ruby-doc.org/stdlib-3.1.1/libdoc/erb/rdoc/ERB.html