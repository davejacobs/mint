require 'spec_helper'

# Mimics the requirement to actually require plugins for
# them to be registered/work.
require 'mint/plugins/epub'

module Mint
  describe EPub do
    describe "#after_publish" do
      let(:document) { Document.new 'content.md', :destination => 'directory' }
      before do
        document.publish!
        document_length = File.read('directory/content.html').length
        EPub.after_publish(document)

        @target_length = document_length / 2
      end

      after do
        FileUtils.rm_r 'directory.epub'
      end

      it "replaces the monolithic published file with a packaged ePub file" do
        File.exist?('directory/content.html').should be_false
        File.exist?('directory.epub').should be_true
      end

      it "ensures all files were compressed using PKZIP"

      context "when the ePub file is unzipped" do
        before do
          # Copy instead of moving to make test cleanup more
          # predictable in nested contexts.
          FileUtils.cp 'directory.epub', 'directory.zip'

          # I will later replace this with my own EPub.unzip! function
          # but don't want to get too distracted now.
          `unzip -o directory.zip -d directory`

          # EPub.unzip! 'directory.zip'
        end

        after do
          FileUtils.rm_r 'directory.zip'
          FileUtils.rm_r 'directory'
        end

        it "contains a META-INF directory" do
          File.exist?('directory/META-INF/container.xml').should be_true
        end

        it "contains an OPS directory" do
          File.exist?('directory/OPS').should be_true
        end

        it "contains a mimetype file" do
          File.exist?('directory/mimetype').should be_true
          File.read('directory/mimetype').chomp.should == 'application/epub+zip'
        end

        it "contains a container file that points to the OPF file" do
          File.exist?('directory/META-INF/container.xml').should be_true
        end

        it "contains an OPF manifest with book metadata" do
          File.exist?('directory/OPS/content.opf').should be_true
        end

        it "contains an NCX file with book spine and TOC" do
          File.exist?('directory/OPS/toc.ncx').should be_true
        end

        it "contains that the OPF refers to the NCX" do
          pending

          opf_text = File.read 'directory/OPS/content.opf'
          opf_xml = Nokogiri::XML::Document.parse opf_text

          # <manifest>
          #   <item id="ncx" href="toc.ncx" 
          #         media-type="application/x-dtbncx+xml" />
          # </manifest>
        end

        it "ensures that OPF and NCX info match" do
          # For docTitle, docAuthor, and meta name="dtb:uid"
        end

        it "splits the document into chapters" do
          chapter1 = File.read 'directory/OPS/chapter-1.html'
          chapter2 = File.read 'directory/OPS/chapter-2.html'
          chapter1.length.should < @target_length
          chapter2.length.should < @target_length
        end

        it "creates a stylesheet for all pages"
      end
    end
    
    describe "#split_on" do
      it "returns a copy of the HTML text it is passed, grouping elements" do
        Document.new('content.md').publish!

        html_text = File.read 'content.html'
        html_document = Nokogiri::HTML.parse(html_text)

        chapters = EPub.split_on(html_document, 'h2')

        expected_document = Nokogiri::HTML.parse <<-HTML
          <div id='container'>
            <div>
              <h2>Header</h2>
              <p>This is just a test.</p>
              <p>Paragraph number two.</p>
            </div>

            <div>
              <h2>Header 2</h2>
              <p>Third sentence.</p>
              <p>Fourth sentence.</p>
            </div>
          </div>
        HTML

        expected_chapters = expected_document.search 'div div'

        cleanse(chapters).should == cleanse(expected_chapters)
      end
    end

    describe "#zip!" do
      before do
        FileUtils.mkdir 'directory'

        files = {
          first: 'First content',
          second: 'Second content',
          third: 'Third content'
        }

        files.each do |name, content|
          File.open "directory/#{name}", 'w' do |f|
            f << content
          end
        end
      end

      after do
        Dir['directory*'].each {|dir| FileUtils.rm_r dir }
        # FileUtils.rm 'directory.zip'
        # FileUtils.rm_r 'directory'
      end

      # This is not a great test of Zip functionality,
      # but I don't really care to spend time on this right now.
      # Most of the details of the Zip file creation will be tested
      # above.
      it "compresses the named file into a directory" do
        EPub.zip! 'directory'
        File.exist?('directory.zip').should be_true
      end
      
      it "accepts an extension parameter" do
        EPub.zip! 'directory', :extension => 'epub'
        File.exist?('directory.epub').should be_true
      end

      it "creates a mimetype entry if specified" do
        pending "a more robust Zip testing strategy"
        EPub.zip! 'directory', :mimetype => 'text/epub'
      end
    end

    def cleanse(dom)
      dom.to_s.squeeze.chomp.gsub(/^\s/, '')
    end
  end
end
