require "pathname"

module Mint
  class DocumentTree
    attr_reader :nodes
    
    # Initializes a new DocumentTree with the given documents
    #
    # @param [Array<Document>] documents array of documents to add to the tree
    def initialize(documents)
      @nodes = []
      documents.each do |document|
        add_document(document.destination_path, document.title, document.source_path)
      end
      sort_nodes!
    end
    
    # Returns new DocumentTree with paths relative to reference_pathname
    # Preserves the tree structure but reorients all paths
    #
    # @param [Pathname] reference_pathname path to the reference pathname
    # @return [DocumentTree] new DocumentTree with paths relative to reference_pathname
    def reorient(reference_pathname)
      reoriented_nodes = reorient_nodes(@nodes, reference_pathname)
      new_tree = DocumentTree.allocate
      new_tree.instance_variable_set(:@nodes, reoriented_nodes)
      new_tree
    end
    
    # Serializes the tree to a flat array for ERB template consumption
    # 
    # ERB templates cannot easily handle recursive tree structures with arbitrary depth,
    # so we flatten the tree into a simple array of hashes that the template can iterate over.
    # Each hash contains the navigation item data (title, paths, depth) needed for rendering.
    #
    # @param [Integer] max_depth maximum navigation depth (optional)
    # @return [Array<Hash>] flattened array of navigation items
    def serialize(max_depth: nil)
      result = []
      flatten_nodes(@nodes, result, max_depth: max_depth)
      result
    end
    
    private
    
    def add_document(path, title, source_path = nil)
      parts = path.to_s.split('/').reject(&:empty?)
      current_nodes = @nodes
      
      parts.each_with_index do |part, idx|
        # Find or create node for this part
        node = current_nodes.find {|n| n.name == part }
        
        if node.nil?
          # Create new node
          path_so_far = Pathname.new(parts[0..idx].join('/'))
          is_file = (idx == parts.length - 1)
          
          node = DocumentTreeNode.new(
            name: part,
            pathname: path_so_far,
            title: is_file ? title : part,
            depth: idx,
            is_file: is_file,
            source_path: is_file ? source_path : nil
          )
          current_nodes << node
        end
        
        current_nodes = node.children
      end
    end
    
    def sort_nodes!
      sort_nodes_recursive(@nodes)
    end
    
    def sort_nodes_recursive(nodes)
      nodes.sort_by! {|node| [node.directory? ? 0 : 1, node.name] }
      nodes.each {|node| sort_nodes_recursive(node.children) }
    end
    
    def reorient_nodes(nodes, reference_pathname)
      nodes.map do |node|
        new_pathname = calculate_relative_path(node.pathname, reference_pathname)
        new_children = reorient_nodes(node.children, reference_pathname)
        
        DocumentTreeNode.new(
          name: node.name,
          pathname: new_pathname,
          title: node.title,
          depth: node.depth,
          is_file: node.file?
        ).tap do |new_node|
          new_node.instance_variable_set(:@children, new_children)
        end
      end
    end
    
    def flatten_nodes(nodes, result, depth = 0, max_depth: nil)
      return if max_depth && depth >= max_depth
      
      nodes.each do |node|
        if node.file?
          result << {
            title: node.title,
            html_path: node.pathname.to_s,
            source_path: node.pathname.to_s,
            depth: depth
          }
        else
          result << {
            title: node.title,
            html_path: nil,
            source_path: nil,
            depth: depth,
            is_directory: true
          }
          
          flatten_nodes(node.children, result, depth + 1, max_depth: max_depth)
        end
      end
    end
    
    def calculate_relative_path(target_pathname, reference_pathname)
      reference_is_file = !reference_pathname.extname.empty?
      reference_dir = reference_is_file ? reference_pathname.dirname : reference_pathname
      
      begin
        relative_path = target_pathname.relative_path_from(reference_dir)
        
        relative_str = relative_path.to_s
        if relative_str.start_with?('../')
          relative_path
        else
          Pathname.new("./#{relative_str}")
        end
      rescue
        target_pathname
      end
    end
  end

  class DocumentTreeNode
    attr_reader :name, :pathname, :title, :children, :depth, :source_path
    
    def initialize(name:, pathname:, title:, depth: 0, is_file: false, source_path: nil)
      @name = name
      @pathname = pathname
      @title = title
      @depth = depth
      @is_file = is_file
      @source_path = source_path
      @children = []
    end
    
    def file?
      @is_file
    end
    
    def directory?
      !@is_file
    end
  end
end