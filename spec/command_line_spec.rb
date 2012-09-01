require 'spec_helper'

module Mint
  describe CommandLine do
    describe ".options" do
      it "provides default options" do
        CommandLine.options['template']['long'].should == 'template'
        CommandLine.options['layout']['long'].should == 'layout'
        CommandLine.options['style']['long'].should == 'style'
      end
    end

    describe ".parser" do
      it "provides a default option parser" do
        fake_argv = ['--layout', 'zen']

        options = {}
        CommandLine.parser {|k, p| options[k] = p }.parse!(fake_argv)
        options[:layout].should == 'zen'
      end

      it "provides an option parser based on a formatted hash" do
        fake_argv = ['--novel', 'novel']
        formatted_options = {
          # Option keys must be formatted as strings, so we
          # use hash-bang syntax
          novel: {
            'short' => 'n',
            'long' => 'novel',
            'parameter' => true,
            'description' => ''
          }
        }

        options = {}

        CommandLine.parser(formatted_options) do |k, p| 
          options[k] = p
        end.parse!(fake_argv)

        options[:novel].should == 'novel'
      end
    end

    describe ".help" do
      it "prints a help message" do
        STDOUT.should_receive(:puts).with('message')
        CommandLine.help('message')
      end
    end

    describe ".install" do
      describe "when there is no template by the specified name" do
        it "installs the specified file as a new template" do
          CommandLine.install("dynamic.sass", :template => "pro")
          Mint.find_template("pro", :style).should == Mint.template_path("pro", :style, :scope => :local, :ext => "sass")
        end
      end
    end

    describe ".uninstall" do
      it "uninstalls the specified template" do
        CommandLine.install("dynamic.sass", :template => "pro")
        CommandLine.uninstall("pro")
        lambda do
          Mint.find_template("pro", :style)
        end.should raise_error
      end
    end

    describe ".edit" do
      it "pulls up a named template file in the user's editor" do
        ENV['EDITOR'] = 'vim'
        CommandLine.should_receive(:system).with("vim #{@dynamic_style_file}")
        CommandLine.edit(@dynamic_style_file)
      end
    end

    describe ".configure" do
      it "writes options to the correct file for the scope specified" do
        Mint.configuration[:layout].should == "default"
        CommandLine.configure({ layout: "pro" }, :local)
        Mint.configuration[:layout].should == "pro"
      end
    end

    describe ".set" do
      it "sets and stores a scoped configuration variable" do
        CommandLine.should_receive(:configure).with({ layout: "pro" }, :local)
        CommandLine.set(:layout, "pro", :scope => :local)
      end
    end

    describe ".publish!" do
      it "publishes a set of files" do
        CommandLine.publish!([@content_file])
        File.exist?("content.html").should be_true
      end
    end
  end
end
