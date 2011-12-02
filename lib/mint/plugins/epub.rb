require 'nokogiri'
require 'hashie'
require 'zip/zip'
require 'zip/zipfilesystem'

# Note: This code is not as clean as I want it to be. It is an example
# plugin with which I'm developing the Mint plugin system. Code cleanup
# to follow.

module Mint
  META_DIR = 'META-INF'
  CONTENT_DIR = 'OPS'

  # Add chapters to document -- this is probably not a sustainable pattern
  # for all plugins, but it's useful here.
  class Document
    def chapters
      html_document = Nokogiri::HTML::Document.parse render
      chapter_contents = EPub.split_on(html_document, 'h2').map &:to_s
      chapter_ids = (1..chapter_contents.length).to_a
      chapters = Hash[chapter_ids.zip chapter_contents]
    end
  end

  class InvalidDocumentError < StandardError; end

  class EPub < Plugin
    def self.after_publish(document)
      # This check doesn't currently follow simlinks
      if document.destination_directory == Dir.getwd
        raise InvalidDocumentError 
      end

      Dir.chdir document.destination_directory do
        metadata = document.metadata
        chapters = document.chapters

        prepare_directory!
        create_chapters! chapters

        create! do |container|
          container.type = 'container'
          container.locals = { chapters: chapters }
        end

        create! do |content|
          content.type = 'content'
          content.locals = { chapters: chapters }
        end

        create! do |toc|
          toc.type = 'toc'
          toc.locals = { chapters: chapters }
        end
      end

      self.zip! document.destination_directory, 
                :mimetype => 'application/epub+zip',
                :extension => 'epub'

      # TODO: I'm not if this is the right thing to do here
      FileUtils.rm_r document.destination_directory
    end
    
    protected
    
    def self.split_on(document, tag_name, opts={})
      container_node = opts[:container] || '#container'

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
            div = node.create_element 'div'
            # div.add_class 'chapter'
            elem.replace div
          end
          div << elem if div
        end
      end

      new_document.search('div div')
    end

    # This is an opinionated version of ZIP, specifically
    # tailored to ePub creation
    def self.zip!(directory, opts={})
      default_opts = {
        extension: 'zip',
        mimetype: nil
      }

      opts = default_opts.merge opts
      extension = opts[:extension]
      parent_directory = File.expand_path "#{directory}/.."
      child_directory = File.basename directory

      Zip::ZipOutputStream.open "#{directory}.#{extension}" do |zos|
        if opts[:mimetype]
          zos.put_next_entry('mimetype', nil, nil, Zip::ZipEntry::STORED)
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

      type = options[:type] || 'container'

      default_options = 
        case type.to_sym
        when :container
          container_defaults
        when :content
          content_defaults
        when :toc
          toc_defaults
        else
          {}
        end

      render_options = default_options.merge options
      create_from_template! render_options
    end

    def self.create_chapters!(chapters)
      chapters.each do |id, text| 
        create_chapter!(id, text)
      end
    end
    
    private

    def self.create_from_template!(opts={})
      template_file = "#{EPub.template_directory}/#{opts[:from]}"
      renderer = Tilt.new template_file, :ugly => false
      content = renderer.render Object.new, opts[:locals]

      File.open(opts[:to], 'w') do |f|
        f << content
      end
    end

    def self.prepare_directory!
      FileUtils.mkdir META_DIR
      FileUtils.mkdir CONTENT_DIR
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
      # chapter_contents = self.split_on(html_document, 'h2')
      # chapter_ids = (1..chapters.length).map {|x| "chapter-#{x}" }
      # chapters = Hash[chapter_ids.zip chapter_contents]
    # end

    def self.create_chapter!(id, text)
      File.open chapter_filename(id), 'w' do |file|
        file << text
      end
    end

    def self.container_defaults
      defaults = {
        from: 'container.haml',
        to: "#{META_DIR}/container.xml",
        locals: {
          opf_file: 'OPS/content.opf'
        }
      }
    end

    def self.content_defaults
      defaults = {
        from: 'content.haml',
        to: "#{CONTENT_DIR}/content.opf",
        locals: {
          title: 'Untitled',
          language: 'English',
          short_title: 'Untitled',
          uuid: '1',
          description: 'No description',
          date: Date.today,
          creators: [{file_as: '', role: ''}],
          contributors: [{file_as: '', role: ''}],
          publisher: '',
          genre: 'Non-fiction',
          rights: 'All Rights Reserved',
          ncx_file: 'toc.ncx',
          style_file: 'style.css',
          title_file: 'title.html',
          chapters: [{ id: '', file: '' }]
        }
      }
    end

    def self.toc_defaults
      defaults = {
        from: 'toc.haml',
        to: "#{CONTENT_DIR}/toc.ncx",
        locals: {
          uuid: '',
          title: 'Title',
          title_file: 'title.title',
          chapters: [{ name: '', file: '' }]
        }
      }
    end
  end
end
