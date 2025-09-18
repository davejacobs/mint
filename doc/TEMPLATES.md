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

## Built-in templates

Mint includes several [ready-to-use templates][built-in templates], which can be consulted as a reference.

## Template variables

Available in layout templates:

- `content` – The converted document content
- `title` – Document title (from first heading or filename)
- `stylesheet_tag` – A fully formed HTML tag representing either inline
  styles or a link to an external stylesheet, according to the user's
  preference (`--style-mode` option)

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