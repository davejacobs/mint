require "spec_helper"

describe Mint::PathTree do
  describe "#initialize" do
    it "creates empty tree from empty pathnames" do
      tree = Mint::PathTree.new([])
      expect(tree.nodes).to be_empty
    end

    it "creates tree from single file" do
      tree = Mint::PathTree.new(["test.md"])
      expect(tree.nodes.length).to eq(1)
      expect(tree.nodes.first.pathname.to_s).to eq("test.md")
      expect(tree.nodes.first.file?).to be true
    end

    it "creates tree from nested files with consistent directory pathnames" do
      tree = Mint::PathTree.new(["docs/guide.md", "docs/api.md"])
      
      expect(tree.nodes.length).to eq(1)
      docs_node = tree.nodes.first
      expect(docs_node.pathname.to_s).to eq("docs")
      expect(docs_node.directory?).to be true
      
      expect(docs_node.children.length).to eq(2)
      guide_node = docs_node.children.find {|n| n.pathname.to_s == "docs/guide.md" }
      api_node = docs_node.children.find {|n| n.pathname.to_s == "docs/api.md" }
      
      expect(guide_node).not_to be_nil
      expect(api_node).not_to be_nil
      expect(guide_node.file?).to be true
      expect(api_node.file?).to be true
    end

    it "creates tree with deeply nested structure" do
      tree = Mint::PathTree.new(["src/components/button/index.md", "src/utils/helpers.md"])
      
      src_node = tree.nodes.first
      expect(src_node.pathname.to_s).to eq("src")
      expect(src_node.directory?).to be true
      
      components_node = src_node.children.find {|n| n.pathname.to_s == "src/components" }
      utils_node = src_node.children.find {|n| n.pathname.to_s == "src/utils" }
      
      expect(components_node).not_to be_nil
      expect(utils_node).not_to be_nil
      
      button_node = components_node.children.first
      expect(button_node.pathname.to_s).to eq("src/components/button")
      
      index_node = button_node.children.first
      expect(index_node.pathname.to_s).to eq("src/components/button/index.md")
      expect(index_node.file?).to be true
    end
  end

  describe "#reoriented" do
    it "reorients paths relative to reference file" do
      tree = Mint::PathTree.new(["docs/guide.md", "docs/api.md"])
      reference = Pathname.new("docs/guide.md")
      
      reoriented = tree.reoriented(reference)
      
      # After reorienting from docs/guide.md, paths should be relative to docs directory
      expect(reoriented.nodes).not_to be_empty
      
      # Convert to navigation array to check relative paths
      nav_array = reoriented.to_navigation_array
      
      # Should contain relative paths: "." for guide.md and "../api.md" for api.md
      guide_item = nav_array.find {|item| item[:html_path] == "." }
      api_item = nav_array.find {|item| item[:html_path] == "../api.md" }
      
      expect(guide_item).not_to be_nil
      expect(api_item).not_to be_nil
      expect(guide_item[:title]).to eq("guide.md")
      expect(api_item[:title]).to eq("api.md")
    end
  end

  describe "#renamed" do
    it "renames paths using regex replacement" do
      tree = Mint::PathTree.new(["docs/guide.md", "docs/api.md"])
      
      renamed = tree.renamed(/\.md$/, '.html')
      
      docs_node = renamed.nodes.first
      guide_node = docs_node.children.find {|n| n.pathname.to_s.include?("guide") }
      api_node = docs_node.children.find {|n| n.pathname.to_s.include?("api") }
      
      expect(guide_node.pathname.to_s).to eq("docs/guide.html")
      expect(api_node.pathname.to_s).to eq("docs/api.html")
    end

    it "preserves directory structure when renaming files" do
      tree = Mint::PathTree.new(["src/components/button.md", "src/utils/helper.md"])
      
      renamed = tree.renamed(/\.md$/, '.html')
      
      src_node = renamed.nodes.first
      expect(src_node.pathname.to_s).to eq("src")
      
      components_node = src_node.children.find {|n| n.pathname.to_s == "src/components" }
      utils_node = src_node.children.find {|n| n.pathname.to_s == "src/utils" }
      
      button_node = components_node.children.first
      helper_node = utils_node.children.first
      
      expect(button_node.pathname.to_s).to eq("src/components/button.html")
      expect(helper_node.pathname.to_s).to eq("src/utils/helper.html")
    end
  end

  describe "#drop" do
    it "returns self when dropping 0 or negative levels" do
      tree = Mint::PathTree.new(["docs/guide.md"])
      
      expect(tree.drop(0)).to eq(tree)
      expect(tree.drop(-1)).to eq(tree)
    end

    it "drops single level from simple structure" do
      tree = Mint::PathTree.new(["docs/guide.md", "docs/api.md"])
      
      dropped = tree.drop(1)
      
      expect(dropped.nodes.length).to eq(2)
      guide_node = dropped.nodes.find {|n| n.pathname.to_s.include?("guide") }
      api_node = dropped.nodes.find {|n| n.pathname.to_s.include?("api") }
      
      expect(guide_node.pathname.to_s).to eq("docs/guide.md")
      expect(api_node.pathname.to_s).to eq("docs/api.md")
      expect(guide_node.file?).to be true
      expect(api_node.file?).to be true
    end

    it "drops multiple levels from nested structure" do
      tree = Mint::PathTree.new(["src/components/button/index.md", "src/components/input/form.md"])
      
      dropped = tree.drop(2) # Drop "src" and "components"
      
      expect(dropped.nodes.length).to eq(2)
      button_node = dropped.nodes.find {|n| n.pathname.to_s.include?("button") }
      input_node = dropped.nodes.find {|n| n.pathname.to_s.include?("input") }
      
      expect(button_node.pathname.to_s).to eq("src/components/button")
      expect(input_node.pathname.to_s).to eq("src/components/input")
      expect(button_node.directory?).to be true
      expect(input_node.directory?).to be true
    end

    it "handles dropping more levels than exist" do
      tree = Mint::PathTree.new(["docs/guide.md"])
      
      dropped = tree.drop(5)
      
      # Should still have nodes, but with minimal paths
      expect(dropped.nodes).not_to be_empty
    end
  end

  describe "#autodrop" do
    it "returns self when multiple top-level nodes exist" do
      tree = Mint::PathTree.new(["docs/guide.md", "src/code.md"])
      
      expect(tree.autodrop).to eq(tree)
    end

    it "drops levels until multiple nodes at top level" do
      tree = Mint::PathTree.new(["common/docs/guide.md", "common/docs/api.md", "common/src/code.md"])
      
      autodropped = tree.autodrop
      
      # Should have dropped "common" level, now showing docs and src directories at top level
      expect(autodropped.nodes.length).to eq(2)
      
      docs_node = autodropped.nodes.find {|n| n.pathname.to_s.include?("docs") }
      src_node = autodropped.nodes.find {|n| n.pathname.to_s.include?("src") }
      
      expect(docs_node.pathname.to_s).to eq("common/docs")
      expect(src_node.pathname.to_s).to eq("common/src")
      expect(docs_node.directory?).to be true
      expect(src_node.directory?).to be true
    end

    it "stops dropping when reaching files at top level" do
      tree = Mint::PathTree.new(["deep/nested/file1.md", "deep/nested/file2.md"])
      
      autodropped = tree.autodrop
      
      # Should have dropped "deep/nested", now showing files at top level
      expect(autodropped.nodes.length).to eq(2)
      expect(autodropped.nodes.all?(&:file?)).to be true
    end

    it "returns self when single file at root" do
      tree = Mint::PathTree.new(["readme.md"])
      
      expect(tree.autodrop).to eq(tree)
    end

    it "handles deeply nested single-child directories" do
      tree = Mint::PathTree.new(["very/deeply/nested/single/path/file.md"])
      
      autodropped = tree.autodrop
      
      # Should drop all directory levels, leaving just the file
      expect(autodropped.nodes.length).to eq(1)
      expect(autodropped.nodes.first.file?).to be true
      expect(autodropped.nodes.first.pathname.to_s).to eq("very/deeply/nested/single/path/file.md")
    end
  end

  describe "#with_navigation_config" do
    it "returns self when config is nil" do
      tree = Mint::PathTree.new(["docs/guide.md"])
      
      expect(tree.with_navigation_config(nil)).to eq(tree)
    end

    it "applies autodrop when navigation_autodrop is true" do
      config = Mint::Config.new(navigation_autodrop: true, navigation_drop: 0)
      tree = Mint::PathTree.new(["common/docs/guide.md", "common/src/code.md"])
      
      result = tree.with_navigation_config(config)
      
      # Should autodrop the common level
      expect(result.nodes.length).to eq(2)
    end

    it "skips autodrop when navigation_autodrop is false" do
      config = Mint::Config.new(navigation_autodrop: false, navigation_drop: 0)
      tree = Mint::PathTree.new(["common/docs/guide.md", "common/src/code.md"])
      
      result = tree.with_navigation_config(config)
      
      # Should not autodrop
      expect(result.nodes.length).to eq(1)
      expect(result.nodes.first.pathname.to_s).to eq("common")
    end

    it "prioritizes autodrop over explicit drop levels when both are specified" do
      config = Mint::Config.new(navigation_autodrop: true, navigation_drop: 1, navigation_depth: 5)
      tree = Mint::PathTree.new(["common/extra/docs/guide.md", "common/extra/src/code.md"])
      
      result = tree.with_navigation_config(config)
      
      # Should only apply autodrop (drops "common" and "extra"), ignoring navigation_drop since they're mutually exclusive
      # Autodrop continues until there are multiple top-level nodes
      nav_array = result.to_navigation_array
      expect(nav_array.any? {|item| item[:title] == "docs" && item[:is_directory] }).to be true
      expect(nav_array.any? {|item| item[:title] == "src" && item[:is_directory] }).to be true
      
      # Files should be present
      guide_item = nav_array.find {|item| item[:title].include?("guide") && !item[:is_directory] }
      code_item = nav_array.find {|item| item[:title].include?("code") && !item[:is_directory] }
      
      expect(guide_item).not_to be_nil
      expect(code_item).not_to be_nil
      
      # Should not contain "common" or "extra" since they were auto-dropped
      expect(nav_array.any? {|item| item[:title] == "common" }).to be false
      expect(nav_array.any? {|item| item[:title] == "extra" }).to be false
    end

    it "applies depth filtering after dropping" do
      config = Mint::Config.new(navigation_autodrop: false, navigation_drop: 0, navigation_depth: 1)
      tree = Mint::PathTree.new(["docs/guide/advanced.md", "docs/api/reference.md"])
      
      result = tree.with_navigation_config(config)
      
      # Should only show top-level "docs" directory (depth 0)
      expect(result.nodes.length).to eq(1)
      expect(result.nodes.first.pathname.to_s).to eq("docs")
    end
  end

  describe "#to_navigation_array" do
    it "converts simple file tree to navigation array" do
      tree = Mint::PathTree.new(["guide.md", "api.md"])
      
      nav_array = tree.to_navigation_array
      
      expect(nav_array.length).to eq(2)
      
      guide_item = nav_array.find {|item| item[:html_path].include?("guide") }
      api_item = nav_array.find {|item| item[:html_path].include?("api") }
      
      expect(guide_item[:title]).to eq("guide.md")
      expect(guide_item[:html_path]).to eq("guide.md")
      expect(guide_item[:depth]).to eq(0)
      
      expect(api_item[:title]).to eq("api.md")
      expect(api_item[:html_path]).to eq("api.md")
      expect(api_item[:depth]).to eq(0)
    end

    it "converts nested tree to navigation array with correct depths" do
      tree = Mint::PathTree.new(["docs/guide.md", "docs/api.md"])
      
      nav_array = tree.to_navigation_array
      
      expect(nav_array.length).to eq(3) # docs directory + 2 files
      
      docs_item = nav_array.find {|item| item[:is_directory] }
      guide_item = nav_array.find {|item| item[:html_path]&.include?("guide") }
      
      expect(docs_item[:title]).to eq("docs")
      expect(docs_item[:depth]).to eq(0)
      expect(docs_item[:is_directory]).to be true
      expect(docs_item[:html_path]).to be_nil
      
      expect(guide_item[:depth]).to eq(1)
      expect(guide_item[:html_path]).to eq("docs/guide.md")
    end
  end
end

describe Mint::PathTreeNode do
  describe "#initialize" do
    it "creates file node" do
      node = Mint::PathTreeNode.new("test.md")
      
      expect(node.pathname.to_s).to eq("test.md")
      expect(node.children).to be_empty
      expect(node.depth).to eq(0)
      expect(node.file?).to be true
      expect(node.directory?).to be false
    end

    it "creates directory node with children" do
      child = Mint::PathTreeNode.new("child.md")
      node = Mint::PathTreeNode.new("parent", children: [child], depth: 1)
      
      expect(node.pathname.to_s).to eq("parent")
      expect(node.children.length).to eq(1)
      expect(node.children.first).to eq(child)
      expect(node.depth).to eq(1)
      expect(node.file?).to be false
      expect(node.directory?).to be true
    end

    it "uses custom title when provided" do
      node = Mint::PathTreeNode.new("test.md", title: "Custom Title")
      
      expect(node.title).to eq("Custom Title")
    end
  end

  describe "#reoriented_relative_to" do
    it "calculates relative paths correctly" do
      node = Mint::PathTreeNode.new("docs/api.md")
      reference = Pathname.new("docs/guide.md")
      
      reoriented = node.reoriented_relative_to(reference)
      
      expect(reoriented.pathname.to_s).to eq("../api.md")
    end

    it "reorients children recursively" do
      child = Mint::PathTreeNode.new("docs/sub/file.md")
      parent = Mint::PathTreeNode.new("docs", children: [child])
      reference = Pathname.new("docs/guide.md")
      
      reoriented = parent.reoriented_relative_to(reference)
      
      reoriented_child = reoriented.children.first
      expect(reoriented_child.pathname.to_s).to eq("../sub/file.md")
    end
  end

  describe "#renamed" do
    it "renames pathname using regex" do
      node = Mint::PathTreeNode.new("test.md")
      
      renamed = node.renamed(/\.md$/, '.html')
      
      expect(renamed.pathname.to_s).to eq("test.html")
    end

    it "renames children recursively" do
      child = Mint::PathTreeNode.new("child.md")
      parent = Mint::PathTreeNode.new("parent", children: [child])
      
      renamed = parent.renamed(/\.md$/, '.html')
      
      renamed_child = renamed.children.first
      expect(renamed_child.pathname.to_s).to eq("child.html")
    end

    it "preserves title when renaming" do
      node = Mint::PathTreeNode.new("test.md", title: "Custom Title")
      
      renamed = node.renamed(/\.md$/, '.html')
      
      expect(renamed.title).to eq("Custom Title")
    end
  end
end