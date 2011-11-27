require 'nokogiri'
require 'zip/zip'
require 'zip/zipfilesystem'

# Note: This code is not as clean as I want it to be. It is an example
# plugin with which I'm developing the Mint plugin system. Code cleanup
# to follow.

module Mint
  class InvalidDocumentError < StandardError; end

  class EPub < Plugin
    def self.after_publish(document)
      # Doesn't currently follow simlinks
      return if document.destination_directory == Dir.getwd

      Dir.chdir document.destination_directory do
        html_text = File.read document.destination_file
        html_document = Nokogiri::HTML::Document.parse html_text
        *chapters = self.split_on(html_document, 'h2')
        

        FileUtils.mkdir 'META-INF'
        FileUtils.mkdir 'OPS'

        render :container, :to => 'META-INF/container.xml'
        render :opf, :to => 'OPS/content.opf'
        render :ncx, :to => 'OPS/toc.ncx'
        render :chapters, :to => 'chapter-X.html'

        chapters.each_with_index do |chapter, i|
          File.open "OPS/chapter-#{i + 1}.html", 'w' do |file|
            file << chapter.to_s
          end
        end
      end

      self.zip! document.destination_directory, 
                :mimetype => 'application/epub+zip',
                :extension => 'epub'

      # TODO: I'm not sure what I should actually be doing here
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

    def self.render(type, locals={})
      case type
      when :container
        defaults = {
          opf_file: 'opf-file'
        }
        locals = defaults.merge locals
        render_template('container.haml', 'META-INF/container.xml', locals)
      when :opf
        defaults = {
          title: 'Title',
          language: 'English',
          short_title: 'T',
          uuid: '1234',
          description: 'description',
          date: '12/31/09',
          creators: [{file_as: '', role: ''}],
          contributors: [{file_as: '', role: ''}],
          publisher: 'O\'reilly',
          genre: 'Fiction',
          rights: 'Rights',
          ncx_file: 'file',
          style_files: [1, 2, 3, 4],
          title_file: 'title.title',
          chapters: [{ name: '', file: '' }]
        }
        locals = defaults.merge locals
        render_template('opf.haml', 'OPS/content.opf', locals)
      when :ncx
        defaults = {
          uuid: '',
          title: 'Title',
          title_file: 'title.title',
          chapters: [{ name: '', file: '' }]
        }
        locals = defaults.merge locals
        render_template('ncx.haml', 'OPS/toc.ncx', locals)
      when :chapter
        render_template('container.haml', 'OPS/container.xml')
      end
    end

    private

    def self.render_template(file, destination_file, locals={})
      template_file = "#{EPub.template_directory}/#{file}"
      renderer = Tilt.new template_file, :ugly => false
      content = renderer.render Object.new, locals

      File.open(destination_file, 'w') do |f|
        f << content
      end
    end
  end
end
