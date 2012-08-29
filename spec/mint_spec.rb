require 'spec_helper'

describe Mint do
  subject { Mint }

  its(:default_options) do
    should == {
      layout: 'default',
      style: 'default',
      destination: nil,
      style_destination: nil
    }
  end

  its(:directories) { should == { templates: 'templates' } }
  its(:files) { should == { syntax: 'syntax.yaml', defaults: 'defaults.yaml' } }

  describe ".root" do
    it "returns the root of the Mint gem as a string" do
      Mint.root.should == File.expand_path('../../../mint', __FILE__)
    end
  end

  describe ".path" do
    it "returns the Mint lookup path as a string if as_path is false" do
      Mint.path(true).should == [
        Pathname.new("#{Dir.getwd}/.mint"),
        Pathname.new("~/.mint").expand_path,
        Pathname.new(Mint.root + "/config")
      ]
    end

    it "returns the Mint lookup path as a string if as_path is false" do
      Mint.path.should == [
        "#{Dir.getwd}/.mint",
        "~/.mint",
        Mint.root + "/config"
      ]
    end
  end

  describe ".formats" do
    it "includes Markdown" do
      Mint.formats.should include("md")
    end

    it "includes Haml" do
      Mint.formats.should include("haml")
    end
  end

  describe ".css_formats" do
    it "includes Sass" do
      Mint.formats.should include("sass")
    end
  end

  describe ".templates" do
    it "returns all templates if no scopes are passed in" do
      Mint.templates.should include(Mint.root + '/config/templates/default') 
    end
  end

  describe ".renderer" do
    it "creates a valid renderer" do
      Mint.renderer(@content_file).should respond_to(:render)
    end
  end

  describe ".path_for_scope" do
    it "chooses the appropriate path for scope" do
      Mint.path_for_scope(:local).should == "#{Dir.getwd}/.mint"
      Mint.path_for_scope(:user).should == '~/.mint'
      Mint.path_for_scope(:global).should == Mint.root + "/config"
    end
  end

  describe ".lookup_template" do
    it "looks up the correct template according to scope" do
      Mint.lookup_template(:default, :layout).should be_in_template('default')
      Mint.lookup_template(:default, :style).should be_in_template('default')
      Mint.lookup_template(:zen, :layout).should be_in_template('zen')
      Mint.lookup_template(:zen, :style).should be_in_template('zen')
      Mint.lookup_template('layout.haml').should == 'layout.haml'
      Mint.lookup_template('dynamic.sass').should == 'dynamic.sass'
    end
  end

  describe ".find_template" do
    it "finds the correct template according to scope" do
      Mint.find_template('default', :layout).should be_in_template('default')
      Mint.find_template('zen', :layout).should be_in_template('zen')
      Mint.find_template('zen', :style).should be_in_template('zen')
    end

    it "decides whether or not a file is a template file" do
      actual_template = Mint.lookup_template(:default, :layout)
      fake_template = "#{Mint.root}/config/templates/default.css"
      obvious_nontemplate = @dynamic_style_file

      actual_template.should be_a_template
      fake_template.should_not be_a_template
      obvious_nontemplate.should_not be_a_template
    end
  end

  describe ".guess_name_from" do
    it "properly guesses destination file names based on source file names" do
      Mint.guess_name_from('content.md').should == 'content.html'
      Mint.guess_name_from('content.textile').should == 'content.html'
      Mint.guess_name_from('layout.haml').should == 'layout.html'
      Mint.guess_name_from('dynamic.sass').should == 'dynamic.css'
    end
  end

  describe ".destination_file_path and .style_destination_file_path" do
    context "before it publishes a document" do
      let(:document) { Mint::Document.new @content_file }
      subject { document }

      its(:destination_file_path) { should_not exist }
      its(:style_destination_file_path) { should_not exist }
    end

    # These are copied from document_spec.rb. I eventually want to move
    # to this non-OO style of publishing, and this is the transition
    context "when it publishes a document" do
      let(:document) { Mint::Document.new @content_file }
      before { Mint.publish! document }
      subject { document }

      its(:destination_file_path) { should exist }
      its(:style_destination_file_path) { should exist }
    end
  end

  describe ".template_path" do
    it "creates a template in the local directory" do
      Mint.template_path('pro', :layout).should == 
        File.expand_path('.mint/templates/pro/layout.haml') 
    end

    it "allows an extension to be specified" do
      Mint.template_path('pro', :layout, :ext => 'erb').should == 
        File.expand_path('.mint/templates/pro/layout.erb') 
    end

    it "allows a scope to be specified" do
      Mint.template_path('pro', :layout, :scope => :user).should == 
        '~/.mint/templates/pro/layout.haml' 
    end
  end
end
