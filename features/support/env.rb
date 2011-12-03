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
  @aruba_timeout_seconds = 3
  @old_path = ENV['PATH']
  @bin_path = File.expand_path('../../../bin', __FILE__)

  # puts "path is #{@old_path}"
  unless @old_path.include? @bin_path
    puts "changing path to #{@bin_path}"
    system "export PATH=#{@bin_path}:$PATH"
  end
  # puts "now mint command should alias to #{`which mint`}"
end

After do
  # puts "reverting path to #{@old_path}"
  ENV['PATH'] = @old_path
end
