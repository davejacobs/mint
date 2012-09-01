require "nokogiri"
require "hashie"
require "zip/zip"
require "zip/zipfilesystem"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/hash/keys"

# Note: This code is not as clean as I want it to be. It is an example
# plugin with which I'm developing the Mint plugin system. Code cleanup
# to follow.

module Mint
  META_DIR = "META-INF"
  CONTENT_DIR = "OPS"

  # Add chapters to document -- this is probably not a sustainable pattern
  # for all plugins, but it's useful here.
  class Document
    def chapters
      html_document = Nokogiri::HTML::Document.parse render
      EPub.split_on(html_document, "h2").map &:to_s
    end
  end

  class InvalidDocumentError < StandardError; end

  class EPub < Plugin
    def self.after_publish(document)
      # This check doesn't currently follow symlinks
      if document.destination_directory == Dir.getwd
        raise InvalidDocumentError 
      end

      Dir.chdir document.destination_directory do
        metadata = standardized_metadata document
        chapters = document.chapters
        locals = { chapters: chapters }.merge metadata

        prepare_directory!
        create_chapters! chapters, :locals => metadata

        create! do |container|
          container.type = "container"
          container.locals = locals
        end

        create! do |content|
          content.type = "content"
          content.locals = locals
        end

        create! do |toc|
          toc.type = "toc"
          toc.locals = locals
        end

        create! do |title|
          title.type = "title"
          title.locals = locals
        end
      end

      FileUtils.rm document.destination_file

      self.zip! document.destination_directory, 
                :mimetype => "application/epub+zip",
                :extension => "epub"

      FileUtils.rm_r document.destination_directory
    end
    
    protected
    
    def self.split_on(document, tag_name, opts={})
      container_node = opts[:container] || "#container"

      new_document = document.dup.tap do |node|
        container = node.at container_node

        unless container
          raise InvalidDocumentError, 
                "Document doesn't contain expected container: #{container}",
                caller
        end
        
        div = nil
        container.element_children.each do |elem|
          if elem.name == tag_name
            div = node.create_element "div"
            # div.add_class "chapter"
            elem.replace div
          end
          div << elem if div
        end
      end

      new_document.search("div div")
    end

    # This is an opinionated version of ZIP, specifically
    # tailored to ePub creation
    def self.zip!(directory, opts={})
      default_opts = {
        extension: "zip",
        mimetype: nil
      }

      opts = default_opts.merge opts
      extension = opts[:extension]
      parent_directory = File.expand_path "#{directory}/.."
      child_directory = File.basename directory

      Zip::ZipOutputStream.open "#{directory}.#{extension}" do |zos|
        if opts[:mimetype]
          zos.put_next_entry("mimetype", nil, nil, Zip::ZipEntry::STORED)
          zos << opts[:mimetype]
        end

        Dir.chdir parent_directory do
          Dir["#{child_directory}/**/*"].each do |file|
            if File.file? file
              relative_path = Helpers.normalize_path(file, child_directory)
              zos.put_next_entry(relative_path, 
                                 nil, 
                                 nil, 
                                 Zip::ZipEntry::DEFLATED)
              zos << File.read(file)
            end
          end
        end
      end
    end

    def self.create!
      options = Hashie::Mash.new
      yield options if block_given?
      options = options.to_hash.symbolize_keys

      type = options[:type] || "container"
      default_options = 
        case type.to_sym
        when :container
          container_defaults
        when :content
          content_defaults
        when :toc
          toc_defaults
        when :title
          title_defaults
        else
          {}
        end

      create_from_template! default_options.deep_merge(options)
    end

    def self.create_chapters!(chapters, opts={})
      opts = chapter_defaults.deep_merge(opts)
      template_file = EPub.template_directory + "/layouts/layout.haml"
      renderer = Tilt.new template_file, :ugly => true
      chapters.map do |chapter|
        renderer.render Object.new, opts[:locals].merge(:content => chapter)
      end.each_with_index do |text, id| 
        create_chapter!(id + 1, text)
      end
    end
    
    private

    def self.create_from_template!(opts={})
      template_file = EPub.template_directory + "/layouts/#{opts[:from]}"
      renderer = Tilt.new template_file, :ugly => true
      content = renderer.render Object.new, opts[:locals]

      File.open(opts[:to], "w") do |f|
        f << content
      end
    end

    def self.prepare_directory!
      [META_DIR, CONTENT_DIR].each do |dir|
        FileUtils.mkdir dir unless File.exist?(dir)
      end
    end

    def self.locals_lookup_table
      {
        author:     [:creators, :array],
        authors:    [:creators, :array],
        editor:     [:contributors, :array],
        editors:    [:contributors, :array],
        barcode:    [:uuid, :string],
        upc:        [:uuid, :string],
        copyright:  [:rights, :string]
      }
    end

    def self.standardized_metadata(document)
      metadata = document.metadata.merge(:stylesheet => document.stylesheet)
      sanitized_metadata = 
        Helpers.symbolize_keys(metadata, :downcase => true)
      standardized_metadata = 
        Helpers.standardize(sanitized_metadata, 
                            :table => locals_lookup_table)
    end

    def self.chapter_filename(id)
      "OPS/chapter-#{id}.html"
    end

    # def self.metadata_from(document)
      # document.metadata
    # end

    # def self.chapters_from(document)
      # html_text = File.read document.destination_file
      # html_document = Nokogiri::HTML::Document.parse html_text
      # chapter_contents = self.split_on(html_document, "h2")
      # chapter_ids = (1..chapters.length).map {|x| "chapter-#{x}" }
      # chapters = Hash[chapter_ids.zip chapter_contents]
    # end

    def self.create_chapter!(id, text)
      File.open chapter_filename(id), "w" do |file|
        file << text
      end
    end

    def self.chapter_defaults
      {
        locals: {
          title: "Untitled"
        }
      }
    end

    def self.container_defaults
      defaults = {
        from: "container.haml",
        to: "#{META_DIR}/container.xml",
        locals: {
          opf_file: "OPS/content.opf"
        }
      }
    end

    def self.content_defaults
      defaults = {
        from: "content.haml",
        to: "#{CONTENT_DIR}/content.opf",
        locals: {
          title: "Untitled",
          language: "English",
          short_title: "",
          uuid: "Unspecified",
          description: "No description",
          date: Date.today,
          creators: ["Anonymous"],
          contributors: [],
          publisher: "Self published",
          genre: "Non-fiction",
          rights: "All Rights Reserved",
          ncx_file: "toc.ncx",
          stylesheet: "style.css",
          title_file: "title.html",
        }
      }
    end

    def self.toc_defaults
      defaults = {
        from: "toc.haml",
        to: "#{CONTENT_DIR}/toc.ncx",
        locals: {
          uuid: "Unspecified",
          title: "Untitled",
          title_file: "title.html",
        }
      }
    end

    def self.title_defaults
      defaults = {
        from: "title.haml",
        to: "#{CONTENT_DIR}/title.html",
        locals: {
          title: "Untitled",
          creators: ["Anonymous"],
          stylesheet: "style.css"
        }
      }
    end
  end
end
