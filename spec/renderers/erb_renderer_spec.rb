require "spec_helper"
require "mint/renderers/erb_renderer"

RSpec.describe Mint::Renderers::Erb do
  let(:layout_dir) { File.join(__dir__, "../fixtures/templates") }
  let(:layout_path) { File.join(layout_dir, "layout.erb") }

  before(:all) do
    # Create test fixture directory and files
    FileUtils.mkdir_p(File.join(__dir__, "../fixtures/templates"))

    # Create a test layout
    File.write(File.join(__dir__, "../fixtures/templates/layout.erb"), <<~ERB)
      <html>
        <head><title><%= title %></title></head>
        <body>
          <%= render 'header' %>
          <main><%= content %></main>
          <%= render 'footer', year: 2024 %>
        </body>
      </html>
    ERB

    # Create test partials
    File.write(File.join(__dir__, "../fixtures/templates/_header.erb"), <<~ERB)
      <header>
        <h1><%= title %></h1>
        <%= render 'navigation' if show_nav %>
      </header>
    ERB

    File.write(File.join(__dir__, "../fixtures/templates/_navigation.erb"), <<~ERB)
      <nav>
        <ul>
          <% nav_items.each do |item| %>
            <li><a href="<%= item[:url] %>"><%= item[:title] %></a></li>
          <% end %>
        </ul>
      </nav>
    ERB

    File.write(File.join(__dir__, "../fixtures/templates/_footer.erb"), <<~ERB)
      <footer>
        <p>&copy; <%= year %> - <%= title %></p>
      </footer>
    ERB
  end

  after(:all) do
    # Clean up test fixtures
    FileUtils.rm_rf(File.join(__dir__, "../fixtures"))
  end

  describe ".render" do
    it "renders basic ERB templates" do
      template = "<h1><%= title %></h1><p><%= content %></p>"
      variables = { title: "Test Page", content: "Hello World" }

      result = described_class.render(template, variables)

      expect(result).to eq("<h1>Test Page</h1><p>Hello World</p>")
    end

    it "renders partials relative to layout path" do
      variables = {
        title: "Test Site",
        content: "<p>Main content</p>".html_safe,
        show_nav: false
      }

      layout_content = File.read(layout_path)
      result = described_class.render(layout_content, variables, layout_path: layout_path)

      expect(result).to include("<title>Test Site</title>")
      expect(result).to include("<h1>Test Site</h1>")
      expect(result).to include("<main><p>Main content</p></main>")
      expect(result).to include("&copy; 2024 - Test Site")
    end

    it "passes locals to partials" do
      variables = {
        title: "Test Site",
        content: "<p>Main content</p>".html_safe,
        show_nav: false
      }

      layout_content = File.read(layout_path)
      result = described_class.render(layout_content, variables, layout_path: layout_path)

      expect(result).to include("&copy; 2024 - Test Site")
    end

    it "supports recursive partial rendering" do
      variables = {
        title: "Test Site",
        content: "<p>Main content</p>".html_safe,
        show_nav: true,
        nav_items: [
          { title: "Home", url: "/" },
          { title: "About", url: "/about" }
        ]
      }

      layout_content = File.read(layout_path)
      result = described_class.render(layout_content, variables, layout_path: layout_path)

      expect(result).to include("<nav>")
      expect(result).to include('<a href="/">Home</a>')
      expect(result).to include('<a href="/about">About</a>')
    end

    it "raises error for missing partials" do
      template = "<%= render 'nonexistent' %>"

      expect {
        described_class.render(template, {}, layout_path: layout_path)
      }.to raise_error(/Partial not found/)
    end

    it "includes JavaScript files with javascript_tag" do
      # Ensure the test JavaScript file exists
      File.write(File.join(__dir__, "../fixtures/templates/test.js"), "console.log('Test JavaScript loaded');")

      template = "<%= javascript_tag 'test.js' %>"

      result = described_class.render(template, {}, layout_path: layout_path)

      expect(result).to include("<script>")
      expect(result).to include("console.log('Test JavaScript loaded');")
      expect(result).to include("</script>")
    end

    it "handles missing JavaScript files gracefully" do
      template = "<%= javascript_tag 'missing.js' %>"

      result = described_class.render(template, {}, layout_path: layout_path)

      expect(result).to include("<!-- JavaScript file not found:")
      expect(result).to include("missing.js -->")
    end

    it "supports recursive partial rendering" do
      # Create a test partial that renders another partial
      File.write(File.join(__dir__, "../fixtures/templates/_recursive_partial.erb"), <<~ERB)
        <div class="outer">
          <%= render 'inner_partial', message: "Hello from outer" %>
        </div>
      ERB

      File.write(File.join(__dir__, "../fixtures/templates/_inner_partial.erb"), <<~ERB)
        <span class="inner"><%= message %></span>
      ERB

      template = '<%= render "recursive_partial" %>'

      result = described_class.render(template, {}, layout_path: layout_path)

      expect(result).to include('<div class="outer">')
      expect(result).to include('<span class="inner">Hello from outer</span>')
    end
  end

  describe "RenderContext" do
    let(:variables) { { title: "Test", content: "Content" } }
    let(:context) { described_class::RenderContext.new(variables, layout_path) }

    it "provides access to variables as methods" do
      expect(context.title).to eq("Test")
      expect(context.content).to eq("Content")
    end

    it "provides access to variables as instance variables" do
      binding_context = context.get_binding
      expect(eval("@title", binding_context)).to eq("Test")
      expect(eval("@content", binding_context)).to eq("Content")
    end
  end
end