require 'spec_helper'

describe Mint do
  subject { Mint }
  its(:root) { should == File.expand_path('../../../mint', __FILE__) }
  its(:path) { should == ["#{Dir.getwd}/.mint", "~/.mint", Mint.root] }
  its(:directories) { should == { templates: 'templates' } }
  its(:files) { should == { config: 'config.yaml' } }
  its(:formats) { should include('md') }
  its(:css_formats) { should include('sass') }

  its(:default_options) do
    should == {
      layout: 'default',
      style: 'default',
      destination: nil,
      style_destination: nil
    }
  end

  it "creates a valid renderer" do
    Mint.renderer(@content_file).should respond_to(:render)
  end

  it "chooses the appropriate path for scope" do
    Mint.path_for_scope(:local).should == "#{Dir.getwd}/.mint"
    Mint.path_for_scope(:user).should == '~/.mint'
    Mint.path_for_scope(:global).should == Mint.root
  end

  it "looks up the correct template according to scope" do
    Mint.lookup_template(:default, :layout).should be_in_template('default')
    Mint.lookup_template(:default, :style).should be_in_template('default')
    Mint.lookup_template(:pro, :layout).should be_in_template('pro')
    Mint.lookup_template(:pro, :style).should be_in_template('pro')
    Mint.lookup_template('layout.haml').should == 'layout.haml'
    Mint.lookup_template('dynamic.sass').should == 'dynamic.sass'
  end

  it "finds the correct template according to scope"

  it "properly guesses destination file names based on source file names" do
    Mint.guess_name_from('content.md').should == 'content.html'
    Mint.guess_name_from('content.textile').should == 'content.html'
    Mint.guess_name_from('layout.haml').should == 'layout.html'
    Mint.guess_name_from('dynamic.sass').should == 'dynamic.css'
  end
end
