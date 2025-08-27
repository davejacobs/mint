require "spec_helper"

describe Mint do
  # Remove unintended side effects of creating
  # new plugins in other files.
  before { Mint.clear_plugins! }
  after { Mint.clear_plugins! }

  describe ".plugins" do
    it "returns all registered plugins" do
      plugin = Class.new(Mint::Plugin)
      expect(Mint.plugins).to eq([plugin])
    end

    it "returns an empty array if there are no registered plugins" do
      expect(Mint.plugins).to eq([])
    end
  end

  describe ".register_plugin!" do
    let(:plugin) { Class.new }

    it "registers a plugin once" do
      Mint.register_plugin! plugin
      expect(Mint.plugins).to eq([plugin])
    end

    it "does not register a plugin more than once" do
      Mint.register_plugin! plugin
      expect { Mint.register_plugin! plugin }.not_to change { Mint.plugins }
      expect(Mint.plugins).to eq([plugin])
    end
  end

  describe ".activate_plugin!" do
    let(:plugin) { Class.new }

    it "activates a plugin once" do
      Mint.activate_plugin! plugin
      expect(Mint.activated_plugins).to eq [plugin]
    end

    it "does not register a plugin more than once" do
      Mint.activate_plugin! plugin
      expect { Mint.activate_plugin! plugin }.not_to change { Mint.activated_plugins }
      expect(Mint.activated_plugins).to eq [plugin]
    end
  end

  describe ".clear_plugins!" do
    let(:plugin) { Class.new }

    it "does nothing if no plugins are registered" do
      expect { Mint.clear_plugins! }.not_to raise_error
    end

    it "removes all registered plugins" do
      Mint.register_plugin! plugin
      expect { Mint.clear_plugins! }.to change { Mint.plugins.length }.by(-1)
    end

    it "removes all activated plugins" do
      Mint.activate_plugin! plugin
      expect { Mint.clear_plugins! }.to change { Mint.activated_plugins.length }.by(-1)
    end
  end

  describe ".template_directory" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      expect(plugin).to receive(:name).and_return("DocBook")
      expect(Mint.template_directory(plugin)).to eq(
        Mint::ROOT + "/plugins/templates/doc_book")
    end
  end

  describe ".config_directory" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      expect(plugin).to receive(:name).and_return("DocBook")
      expect(Mint.config_directory(plugin)).to eq(
        Mint::ROOT + "/plugins/config/doc_book")
    end
  end

  describe ".commandline_options_file" do
    let(:plugin) { Class.new(Mint::Plugin) }

    it "gives access to a directory where template files can be stored" do
      expect(plugin).to receive(:name).and_return("DocBook")
      expect(Mint.commandline_options_file(plugin)).to eq(
        Mint::ROOT + "/plugins/config/doc_book/syntax.yml")
    end
  end

  [:before_render, :after_render].each do |callback|
    describe ".#{callback}" do
      let(:first_plugin) { Class.new(Mint::Plugin) }
      let(:second_plugin) { Class.new(Mint::Plugin) }
      let(:third_plugin) { Class.new(Mint::Plugin) }

      context "when plugins are specified" do
        before do
          expect(first_plugin).to receive(callback).ordered.and_return("first")
          expect(second_plugin).to receive(callback).ordered.and_return("second")
          expect(third_plugin).to receive(callback).never
        end

        it "reduces .#{callback} across all specified plugins in order" do
          plugins = [first_plugin, second_plugin]
          expect(Mint.send(callback, "text", :plugins => plugins)).to eq("second")
        end
      end

      context "when plugins are activated, but no plugins are specified" do
        before do
          expect(first_plugin).to receive(callback).ordered.and_return("first")
          expect(second_plugin).to receive(callback).ordered.and_return("second")
          expect(third_plugin).to receive(callback).never
        end
        
        it "reduces .#{callback} across all activated plugins in order" do
          Mint.activate_plugin! first_plugin
          Mint.activate_plugin! second_plugin
          expect(Mint.send(callback, "text")).to eq("second")
        end
      end

      context "when plugins are not specified" do
        before do
          expect(first_plugin).to receive(callback).never
          expect(second_plugin).to receive(callback).never
          expect(third_plugin).to receive(callback).never
        end
        
        it "returns the parameter text" do
          expect(Mint.send(callback, "text")).to eq("text")
        end
      end
    end
  end

  describe ".after_publish" do
    let(:first_plugin) { Class.new(Mint::Plugin) }
    let(:second_plugin) { Class.new(Mint::Plugin) }
    let(:third_plugin) { Class.new(Mint::Plugin) }

    context "when plugins are specified" do
      before do
        expect(first_plugin).to receive(:after_publish).ordered
        expect(second_plugin).to receive(:after_publish).ordered
        expect(third_plugin).to receive(:after_publish).never
      end

      it "iterates across all specified plugins in order" do
        plugins = [first_plugin, second_plugin]
        Mint.after_publish("fake document", :plugins => plugins)
      end
    end

    context "when plugins are activated, but no plugins are specified" do
      before do
        expect(first_plugin).to receive(:after_publish).ordered
        expect(second_plugin).to receive(:after_publish).ordered
        expect(third_plugin).to receive(:after_publish).never
      end
      
      it "iterates across all activated plugins in order" do
        Mint.activate_plugin! first_plugin
        Mint.activate_plugin! second_plugin
        Mint.after_publish("fake document")
      end
    end

    context "when plugins are not specified" do
      before do
        expect(first_plugin).to receive(:after_publish).never
        expect(second_plugin).to receive(:after_publish).never
        expect(third_plugin).to receive(:after_publish).never
      end
      
      it "does not iterate over any plugins" do
        Mint.after_publish("fake document")
      end
    end
  end

  # TODO: Document expected document functionality changes related to plugins
  describe Mint::Document do
    context "when plugins are registered with Mint" do
      describe "#content=" do
        it "applies each registered plugin's before_render filter"
      end

      describe "#render" do
        it "applies each registered plugin's after_render filter"
      end

      describe "#publish!" do
        it "applies each registered plugin's after_publish filter"
      end
    end
  end

  describe Mint::Plugin do
    # We have to instantiate these plugins in a before block,
    # and not in a let block. Because lets are lazily evaluated,
    # the first two tests in the "#inherited" suite will not
    # pass.
    before do
      @first_plugin = Class.new(Mint::Plugin)
      @second_plugin = Class.new(Mint::Plugin)
    end

    describe ".underscore" do
      let(:plugin) { Class.new(Mint::Plugin) }

      it "when anonymous, returns a random identifier"

      it "when named, returns its name, underscored" do
        expect(plugin).to receive(:name).and_return("EPub")
        expect(plugin.underscore).to eq("epub")
      end
    end

    describe ".inherited" do
      it "registers the subclass with Mint as a plugin" do
        expect do
          Class.new(Mint::Plugin)
        end.to change { Mint.plugins.length }.by(1)
      end

      it "preserves the order of subclassing" do
        expect(Mint.plugins).to eq([@first_plugin, @second_plugin])
      end

      it "does not change the order of a plugin when it is monkey-patched" do
        expect do
          @first_plugin.instance_eval do 
            def monkey_patch
            end
          end
        end.not_to change { Mint.plugins }
      end
    end

    describe ".commandline_options" do
      let(:plugin) { Class.new(Mint::Plugin) }
      before do
        plugin.instance_eval do
          def commandline_options
          end
        end
      end

      it "returns a hash of options the plugin can take, including constraints"
    end

    context "plugin callbacks" do
      let(:plugin) { Class.new(Mint::Plugin) }

      describe ".before_render" do
        it "allows changes to the un-rendered content" do
          plugin.instance_eval do
            def before_render(text_document)
              "base"
            end
          end

          expect(plugin.before_render("text")).to eq("base")
        end
      end

      describe ".after_render" do
        it "allows changes to the rendered HTML" do
          plugin.instance_eval do
            def after_render(html_document)
              "<!doctype html>"
            end
          end

          expect(plugin.after_render("<html></html>")).to eq("<!doctype html>")
        end
      end

      describe ".after_mint" do
        let(:document) { Mint::Document.new "content.md" } 

        it "allows changes to the document extension" do
          plugin.class_eval do
            def self.after_publish(document)
              document.name.gsub! /html$/, "htm"
            end
          end

          expect do
            plugin.after_publish(document)
          end.to change { document.name.length }.by(-1)
        end

        it "allows splitting up the document into two, without garbage" do
          plugin.class_eval do
            def self.after_publish(document)
              content = document.content
              fake_splitting_point = content.length / 2

              first  = content[0..fake_splitting_point]
              second = content[fake_splitting_point..-1]

              File.open "first-half.html", "w+" do |file|
                file << first
              end

              File.open "second-half.html", "w+" do |file|
                file << second
              end

              File.delete document.destination_file
            end
          end

          document.publish! :plugins => [plugin]

          expect(File.exist?(document.destination_file)).to be_falsy
          expect(File.exist?("first-half.html")).to be_truthy
          expect(File.exist?("second-half.html")).to be_truthy
        end

        it "allows changes to the style file" do
          pending "figure out a better strategy for style manipulation"
          document = Mint::Document.new "content.md", :style => "style.css" 

          plugin.instance_eval do
            def after_publish(document)
              # I'd like to take document.style_destination_file,
              # but the current Mint API doesn't allow for this
              # if we're setting the style via a concrete
              # stylesheet in our current directory
              style_source = document.style.source_file
              style = File.read style_source
              File.open style_source, "w" do |file|
                file << style.gsub(/#/, ".")
              end
            end
          end

          document.publish! :plugins => [plugin]

          File.read(document.style.source_file).should =~ /\#container/
        end

        context "when the output is in the default directory" do
          it "doesn't allow changes to the document directory" do
            pending "figuring out the best way to prevent directory manipulation"
            document = Mint::Document.new "content.md"
            plugin.instance_eval do
              def after_publish
                original = document.destination_directory
                new = File.expand_path "invalid"
                FileUtils.mv original, new
                document.destination = "invalid"
              end

              expect do
                document.publish! :plugins => [plugin]
              end.to raise_error(InvalidPluginAction)
            end
          end
        end

        context "when the output is a new directory" do
          it "allows changes to the document directory" do
            document = Mint::Document.new "content.md", :destination => "destination"
            plugin.class_eval do
              def self.after_publish(document)
                original = document.destination_directory
                new = File.expand_path "book"
                FileUtils.mv original, new
                document.destination = "book"
              end
            end

            document.publish! :plugins => [plugin]
            expect(File.exist?("destination")).to be_falsy
            expect(File.exist?("book")).to be_truthy
            expect(document.destination_directory).to eq(File.expand_path("book"))
          end

          it "allows compression of the final output" do
            require "zip"
            require "zip/filesystem"

            document = Mint::Document.new "content.md", :destination => "destination"
            plugin.class_eval do
              def self.after_publish(document)
                Zip::OutputStream.open("book.zip") do |zos|
                  zos.put_next_entry("chapter-1.html")
                  zos.puts File.read(document.destination_file)
                end

                FileUtils.mv "book.zip", "book.epub"
              end
            end

            document.publish! :plugins => [plugin]

            expect(File.exist?("destination")).to be_truthy
            expect(File.exist?("book.zip")).to be_falsy
            expect(File.exist?("book.epub")).to be_truthy

            directory_size = 
              Dir["#{document.destination_directory}/**/*"].
              flatten.
              map {|file| File.stat(file).size }.
              reduce(&:+)
            compressed_size = File.stat("book.epub").size
            expect(directory_size).to be > compressed_size
          end
        end

        context "when the style output is a new directory" do
          it "allows changes to the style directory" do
            document = Mint::Document.new "content.md", :style_destination => "styles"
            plugin.class_eval do
              def self.after_publish(document)
                original = document.style_destination_directory
                new = File.expand_path "looks"
                FileUtils.mv original, new
                document.style_destination = "looks"
              end
            end

            document.publish! :plugins => [plugin]

            expect(File.exist?("styles")).to be_falsy
            expect(File.exist?("looks")).to be_truthy
            expect(document.style_destination_directory).to eq(File.expand_path("looks"))
          end

          after do
            FileUtils.rm_r File.expand_path("looks")
          end
        end
      end
    end
  end
end
