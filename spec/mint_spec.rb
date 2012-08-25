require 'spec_helper'

describe Mint do
  subject { Mint }
  its(:root) { should == File.expand_path('../../../mint', __FILE__) }
  its(:path) { should == ["#{Dir.getwd}/.mint", "~/.mint", Mint.root + "/config"] }
  its(:formats) { should include('md') }
  its(:css_formats) { should include('sass') }
  its(:templates) { should include(Mint.root + '/config/templates/default') }

  its(:default_options) do
    should == {
      layout: 'default',
      style: 'default',
      destination: nil,
      style_destination: nil
    }
  end

  its(:directories) do 
    should == { 
      templates: 'templates'
    }
  end

  its(:files) do 
    should == { 
      syntax: 'syntax.yaml',
      defaults: 'defaults.yaml' 
    }
  end

  it "creates a valid renderer" do
    Mint.renderer(@content_file).should respond_to(:render)
  end

  it "chooses the appropriate path for scope" do
    Mint.path_for_scope(:local).should == "#{Dir.getwd}/.mint"
    Mint.path_for_scope(:user).should == '~/.mint'
    Mint.path_for_scope(:global).should == Mint.root + "/config"
  end

  it "looks up the correct template according to scope" do
    Mint.lookup_template(:default, :layout).should be_in_template('default')
    Mint.lookup_template(:default, :style).should be_in_template('default')
    Mint.lookup_template(:zen, :layout).should be_in_template('zen')
    Mint.lookup_template(:zen, :style).should be_in_template('zen')
    Mint.lookup_template('layout.haml').should == 'layout.haml'
    Mint.lookup_template('dynamic.sass').should == 'dynamic.sass'
  end

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

  it "properly guesses destination file names based on source file names" do
    Mint.guess_name_from('content.md').should == 'content.html'
    Mint.guess_name_from('content.textile').should == 'content.html'
    Mint.guess_name_from('layout.haml').should == 'layout.html'
    Mint.guess_name_from('dynamic.sass').should == 'dynamic.css'
  end

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
