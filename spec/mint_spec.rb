require "spec_helper"

describe Mint do
  describe "::PROJECT_ROOT" do
    it "contains the root of the Mint gem as a string" do
      expect(Mint::PROJECT_ROOT).to eq(File.expand_path("../..", __FILE__))
    end
  end

  describe "::PATH" do
    it "returns the paths corresponding to all scopes as an array" do
      expect(Mint::PATH).to eq([Pathname.new(".mint"),
                               Pathname.new("~/.config/mint").expand_path,
                               Pathname.new(Mint::PROJECT_ROOT + "/config").expand_path])
    end
  end

  describe ".configuration" do
    context "when there is no config.toml file on the Mint path" do
      it "returns a default Config object" do
        config = Mint.configuration
        expect(config).to be_a(Mint::Config)
        expect(config.layout_name).to eq('default')
        expect(config.style_name).to eq('default')
        expect(config.style_mode).to eq(:inline)
        expect(config.output_file_format).to eq('%{name}.%{ext}')
      end
    end

    context "when there is a config.toml file on the Mint path" do
      before do
        FileUtils.mkdir_p(".mint")
        File.write(".mint/config.toml", "style = \"custom\"")
      end

      after do
        FileUtils.rm_rf(".mint")
      end

      it "merges config files with defaults" do
        config = Mint.configuration
        expect(config.style_name).to eq("custom")
        expect(config.layout_name).to eq("default") # still has defaults
      end
    end
  end
end