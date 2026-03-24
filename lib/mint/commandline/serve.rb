require "tmpdir"
require "webrick"
require "fileutils"

require_relative "../config"

module Mint
  module Commandline
    def self.serve!(source_files, config:)
      config = Config.ensure_config(config)
      port = config.serve_port

      tmp_dir = Dir.mktmpdir("mint-serve-")

      begin
        serve_config = Config.new(config.to_h.merge(
          destination_directory: Pathname.new(tmp_dir),
          style_mode: :inline
        ))

        publish!(source_files, config: serve_config)

        log = WEBrick::Log.new(nil, WEBrick::BasicLog::ERROR)
        server = WEBrick::HTTPServer.new(
          Port: port,
          Logger: log,
          AccessLog: []
        )

        server.mount_proc "/" do |req, res|
          path = req.path.gsub(/\.\./, "")
          file_path = File.join(tmp_dir, path)

          resolved =
            if File.file?(file_path)
              file_path
            elsif File.file?("#{file_path}.html")
              "#{file_path}.html"
            elsif File.file?(File.join(file_path, "index.html"))
              File.join(file_path, "index.html")
            end

          if resolved
            res.status = 200
            res.content_type = WEBrick::HTTPUtils.mime_type(resolved, WEBrick::HTTPUtils::DefaultMimeTypes)
            res.body = File.binread(resolved)
          else
            res.status = 404
            res.content_type = "text/plain"
            res.body = "Not found: #{req.path}"
          end
        end

        trap("INT") { server.shutdown }
        trap("TERM") { server.shutdown }

        puts "Serving on http://localhost:#{port} (press Ctrl+C to stop)"
        server.start
      ensure
        FileUtils.rm_rf(tmp_dir)
      end
    end
  end
end
