require "aruba/cucumber"

Before do
  @aruba_timeout_seconds            = 5
  @original_path, ENV["PATH"]       = ENV["PATH"], "../../bin:#{ENV['PATH']}"
  @original_rubylib, ENV["RUBYLIB"] = ENV["RUBYLIB"], "../../lib"
  ENV["MINT_NO_PIPE"]               = "true"
end

After do
  ENV["PATH"]         = @original_path
  ENV["RUBYLIB"]      = @original_rubylib
  ENV["MINT_NO_PIPE"] = nil
  FileUtils.rm_rf "tmp/aruba"
end
