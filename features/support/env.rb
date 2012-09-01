require 'aruba/cucumber'

$LOAD_PATH.unshift File.expand_path('../../../lib', __FILE__)

module ArubaOverrides
  def detect_ruby(cmd)
    if cmd =~ /^mint/
      "ruby -I ../../lib -S ../../bin/#{cmd}"
    else
      super(cmd)
    end
  end
end

World(ArubaOverrides)

Before do
  ENV['MINT_NO_PIPE'] = "true"
  @aruba_timeout_seconds = 3
  @old_path = ENV['PATH']
  @bin_path = File.expand_path('../../../bin', __FILE__)

  unless @old_path.include? @bin_path
    system "export PATH=#{@bin_path}:$PATH"
  end
end

After do
  FileUtils.rm_rf "tmp/aruba/.mint"
  ENV['PATH'] = @old_path
  ENV['MINT_NO_PIPE'] = nil
end
