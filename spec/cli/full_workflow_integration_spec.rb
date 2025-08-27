require "spec_helper"

RSpec.describe "Full CLI Workflow Integration" do
  describe "complete user workflows" do
    context "in isolated environment" do
      around(:each) do |example|
        in_temp_dir do |dir|
          @test_dir = dir
          example.run
        end
      end

      describe "new user getting started" do
        it "can set up a new project from scratch" do
          # 1. Initialize configuration
          expect {
            Mint::CommandLine.set("author", "Test User", :local)
            Mint::CommandLine.set("layout", "clean", :local)
          }.not_to raise_error

          # 2. Create a custom template
          layout_content = <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <title>My Site</title>
              <% if style %>
                <link rel="stylesheet" href="<%= style %>">
              <% end %>
            </head>
            <body>
              <header>
                <h1>My Site</h1>
              </header>
              <main>
                <%= content %>
              </main>
              <footer>
                <p>&copy; 2024 Test User</p>
              </footer>
            </body>
            </html>
          HTML

          create_template_file("my-layout.erb", :layout, layout_content)
          Mint::CommandLine.install("my-layout.erb", "clean", :local)

          # 3. Create some content
          create_markdown_file("index.md", <<~MARKDOWN
            # Welcome to My Site
            
            This is the homepage of my new site.
            
            ## Features
            
            - Clean design
            - Easy to maintain
            - Fast loading
            
            Check out my [about page](about.html).
          MARKDOWN
          )

          create_markdown_file("about.md", <<~MARKDOWN
            # About Me
            
            I'm a developer who loves simple, clean websites.
            
            ## Contact
            
            - Email: test@example.com
            - GitHub: @testuser
          MARKDOWN
          )

          # 4. Publish the site
          expect {
            Mint::CommandLine.publish!(["index.md", "about.md"], {})
          }.not_to raise_error

          # 5. Verify everything worked
          expect(File.exist?("index.html")).to be true
          expect(File.exist?("about.html")).to be true

          index_content = File.read("index.html")
          expect(index_content).to include("<h1>My Site</h1>") # header
          expect(index_content).to include("Welcome to My Site") # content
          expect(index_content).to include("Test User") # footer
          expect(index_content).to include("about.html") # link

          about_content = File.read("about.html")
          expect(about_content).to include("About Me")
          expect(about_content).to include("test@example.com")
        end
      end

      describe "documentation site workflow" do
        it "can build a multi-page documentation site" do
          # Create a documentation structure
          FileUtils.mkdir_p("docs/guides")
          FileUtils.mkdir_p("docs/api")
          FileUtils.mkdir_p("build")

          # Create navigation template
          nav_layout = <<~ERB
            <!DOCTYPE html>
            <html>
            <head>
              <title>Documentation</title>
              <style>
                body { font-family: sans-serif; margin: 0; }
                .container { display: flex; }
                .sidebar { width: 200px; background: #f5f5f5; padding: 1rem; }
                .content { flex: 1; padding: 1rem; }
                .nav-link { display: block; margin: 0.5rem 0; }
              </style>
            </head>
            <body>
              <div class="container">
                <nav class="sidebar">
                  <h3>Documentation</h3>
                  <% if defined?(all_files) && all_files %>
                    <% all_files.each do |file| %>
                      <% name = File.basename(file, '.md') %>
                      <% path = file.gsub('.md', '.html') %>
                      <a href="<%= path %>" class="nav-link"><%= name.tr('-', ' ').capitalize %></a>
                    <% end %>
                  <% end %>
                </nav>
                <main class="content">
                  <%= content %>
                </main>
              </div>
            </body>
            </html>
          ERB

          FileUtils.mkdir_p(".mint/templates/docs")
          File.write(".mint/templates/docs/layout.erb", nav_layout)

          # Create documentation content
          create_markdown_file("docs/index.md", <<~MARKDOWN
            # Project Documentation
            
            Welcome to our comprehensive documentation.
            
            ## Getting Started
            
            See our [installation guide](guides/installation.html) to get up and running.
          MARKDOWN
          )

          create_markdown_file("docs/guides/installation.md", <<~MARKDOWN
            # Installation Guide
            
            ## Prerequisites
            
            - Ruby 2.7+
            - Git
            
            ## Steps
            
            1. Clone the repository
            2. Run `bundle install`
            3. Run `mint publish`
          MARKDOWN
          )

          create_markdown_file("docs/api/overview.md", <<~MARKDOWN
            # API Overview
            
            Our API provides REST endpoints for all major operations.
            
            ## Authentication
            
            All requests require an API key in the header.
          MARKDOWN
          )

          # Configure for documentation
          Mint::CommandLine.set("layout", "docs", :local)
          Mint::CommandLine.set("destination", "build", :local)

          # Publish all documentation
          files = ["docs/index.md", "docs/guides/installation.md", "docs/api/overview.md"]
          Mint::CommandLine.publish!(files, { recursive: false })

          # Verify the documentation site
          expect(File.exist?("build/docs/index.html")).to be true
          expect(File.exist?("build/docs/guides/installation.html")).to be true
          expect(File.exist?("build/docs/api/overview.html")).to be true

          index_content = File.read("build/docs/index.html")
          expect(index_content).to include("Documentation") # nav
          expect(index_content).to include("installation") # nav link
          expect(index_content).to include("Project Documentation") # content
        end
      end

      describe "blog workflow" do
        it "can manage a simple blog" do
          # Create blog structure
          FileUtils.mkdir_p("posts")
          FileUtils.mkdir_p("output")

          # Create blog template
          blog_layout = <<~ERB
            <!DOCTYPE html>
            <html>
            <head>
              <title>My Blog</title>
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <style>
                body { 
                  max-width: 800px; 
                  margin: 0 auto; 
                  padding: 2rem; 
                  font-family: Georgia, serif;
                  line-height: 1.6;
                }
                .header { border-bottom: 1px solid #eee; margin-bottom: 2rem; }
                .post-meta { color: #666; font-size: 0.9em; margin-bottom: 1rem; }
                .back-link { margin-top: 2rem; }
              </style>
            </head>
            <body>
              <header class="header">
                <h1><a href="index.html">My Blog</a></h1>
              </header>
              <article>
                <%= content %>
              </article>
              <div class="back-link">
                <a href="index.html">&larr; Back to all posts</a>
              </div>
            </body>
            </html>
          ERB

          FileUtils.mkdir_p(".mint/templates/blog")
          File.write(".mint/templates/blog/layout.erb", blog_layout)

          # Create blog posts
          create_markdown_file("posts/2024-01-15-first-post.md", <<~MARKDOWN
            # My First Blog Post
            
            <div class="post-meta">January 15, 2024</div>
            
            Welcome to my new blog! I'm excited to share my thoughts on:
            
            - Web development
            - Ruby programming  
            - Life and code
            
            Stay tuned for more posts!
          MARKDOWN
          )

          create_markdown_file("posts/2024-01-20-learning-mint.md", <<~MARKDOWN
            # Learning Mint for Static Sites
            
            <div class="post-meta">January 20, 2024</div>
            
            I've been exploring Mint for generating static sites. Here's what I've learned:
            
            ## Why Static Sites?
            
            - Fast loading
            - Easy hosting
            - Version control friendly
            
            ## Getting Started with Mint
            
            The process is straightforward...
          MARKDOWN
          )

          # Create an index page
          create_markdown_file("index.md", <<~MARKDOWN
            # Welcome to My Blog
            
            Recent posts:
            
            - [Learning Mint for Static Sites](posts/2024-01-20-learning-mint.html) - January 20, 2024
            - [My First Blog Post](posts/2024-01-15-first-post.html) - January 15, 2024
          MARKDOWN
          )

          # Configure and publish
          Mint::CommandLine.configure({
            "layout" => "blog",
            "destination" => "output"
          }, :local)

          # Publish all content
          files = Dir.glob("posts/*.md") + ["index.md"]
          Mint::CommandLine.publish!(files, {})

          # Verify blog structure
          expect(File.exist?("output/index.html")).to be true
          expect(File.exist?("output/posts/2024-01-15-first-post.html")).to be true
          expect(File.exist?("output/posts/2024-01-20-learning-mint.html")).to be true

          # Check content
          index_content = File.read("output/index.html")
          expect(index_content).to include("My Blog")
          expect(index_content).to include("Recent posts")

          post_content = File.read("output/posts/2024-01-15-first-post.html")
          expect(post_content).to include("My First Blog Post")
          expect(post_content).to include("January 15, 2024")
          expect(post_content).to include("Back to all posts")
        end
      end

      describe "team collaboration workflow" do
        it "supports shared templates and configuration" do
          # Simulate a team setup with shared templates
          
          # 1. Set up shared template (simulating user scope)
          shared_template = <<~ERB
            <!DOCTYPE html>
            <html>
            <head>
              <title>Company Documentation</title>
              <style>
                body { font-family: 'Helvetica', sans-serif; }
                .company-header { background: #003366; color: white; padding: 1rem; }
                .content { padding: 2rem; }
              </style>
            </head>
            <body>
              <header class="company-header">
                <h1>Acme Corp Documentation</h1>
              </header>
              <div class="content">
                <%= content %>
              </div>
            </body>
            </html>
          ERB

          # Create company template
          FileUtils.mkdir_p(".mint/templates/company")
          File.write(".mint/templates/company/layout.erb", shared_template)

          # 2. Individual developer customizes local config
          Mint::CommandLine.configure({
            "layout" => "company",
            "author" => "Alice Developer",
            "destination" => "team-docs"
          }, :local)

          # 3. Create team documentation
          FileUtils.mkdir_p("team-docs")
          
          create_markdown_file("project-overview.md", <<~MARKDOWN
            # Project Overview
            
            ## Architecture
            
            Our system consists of three main components:
            
            1. Frontend (React)
            2. Backend (Rails API)
            3. Database (PostgreSQL)
            
            ## Deployment
            
            We use Docker for containerization and deploy to AWS.
          MARKDOWN
          )

          # 4. Publish with team template
          Mint::CommandLine.publish!(["project-overview.md"], {})

          # 5. Verify team branding is applied
          expect(File.exist?("team-docs/project-overview.html")).to be true
          
          content = File.read("team-docs/project-overview.html")
          expect(content).to include("Acme Corp Documentation")
          expect(content).to include("company-header")
          expect(content).to include("Project Overview")
        end
      end

      describe "migration and maintenance workflows" do
        it "can migrate templates and preserve content" do
          # Start with old template
          old_template = "<html><body><%= content %></body></html>"
          create_template_file("old.erb", :layout, old_template)
          Mint::CommandLine.install("old.erb", "v1", :local)

          # Create content with old template
          create_markdown_file("document.md", "# My Document\n\nContent here.")
          Mint::CommandLine.publish!(["document.md"], { layout: "v1" })

          old_content = File.read("document.html")
          expect(old_content).to include("My Document")

          # Create new, improved template
          new_template = <<~ERB
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <title>Documentation</title>
            </head>
            <body>
              <div class="container">
                <%= content %>
              </div>
            </body>
            </html>
          ERB

          create_template_file("new.erb", :layout, new_template)
          Mint::CommandLine.install("new.erb", "v2", :local)

          # Migrate to new template
          Mint::CommandLine.publish!(["document.md"], { layout: "v2" })

          new_content = File.read("document.html")
          expect(new_content).to include("My Document") # content preserved
          expect(new_content).to include("<!DOCTYPE html>") # new template features
          expect(new_content).to include("container") # new styling
        end
      end

      describe "error recovery workflows" do
        it "can recover from and fix common mistakes" do
          # 1. Try to use non-existent template (common mistake)
          create_markdown_file("test.md", "# Test")

          expect {
            Mint::CommandLine.publish!(["test.md"], { layout: "nonexistent" })
          }.to raise_error(Mint::TemplateNotFoundException)

          # 2. Create the missing template
          allow(STDIN).to receive(:gets).and_return("y\n") # auto-create
          silence_output do
            mock_editor do
              Mint::CommandLine.edit("nonexistent", :layout, :local)
            end
          end

          # 3. Now publishing should work
          expect {
            Mint::CommandLine.publish!(["test.md"], { layout: "nonexistent" })
          }.not_to raise_error

          expect(File.exist?("test.html")).to be true
        end

        it "handles corrupted configuration gracefully" do
          # Create corrupted config
          FileUtils.mkdir_p(".mint")
          File.write(".mint/config.yaml", "invalid: yaml: content: [")

          # Should still be able to set new config
          expect {
            Mint::CommandLine.set("layout", "recovery", :local)
          }.not_to raise_error

          # Config should now be valid
          config = YAML.load_file(".mint/config.yaml")
          expect(config["layout"]).to eq("recovery")
        end
      end

      describe "performance with large projects" do
        it "handles many files efficiently" do
          # Create a larger number of files
          FileUtils.mkdir_p("large-project")
          setup_basic_config
          create_template_directory("default")

          files = []
          20.times do |i|
            file = "large-project/page-#{i.to_s.rjust(3, '0')}.md"
            content = <<~MARKDOWN
              # Page #{i}
              
              This is page number #{i} in our large project.
              
              ## Content
              
              #{'Lorem ipsum dolor sit amet. ' * 10}
              
              ## Links
              
              - [Previous](page-#{'%03d' % (i-1)}.html) #{i > 0 ? '' : '(none)'}
              - [Next](page-#{'%03d' % (i+1)}.html) #{i < 19 ? '' : '(none)'}
            MARKDOWN
            
            create_markdown_file(file, content)
            files << file
          end

          # Publish all files and measure time
          start_time = Time.now
          
          expect {
            Mint::CommandLine.publish!(files, {})
          }.not_to raise_error
          
          end_time = Time.now
          duration = end_time - start_time

          # Verify all files were created
          20.times do |i|
            expect(File.exist?("large-project/page-#{'%03d' % i}.html")).to be true
          end

          # Should complete in reasonable time (adjust as needed)
          expect(duration).to be < 10.0

          # Verify content quality isn't compromised
          sample_content = File.read("large-project/page-010.html")
          expect(sample_content).to include("Page 10")
          expect(sample_content).to include("Lorem ipsum")
        end
      end
    end
  end
end