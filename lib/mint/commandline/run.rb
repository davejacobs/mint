require_relative "../commandline/parse"
require_relative "../commandline/publish"

module Mint
  module Commandline
    def self.run!(argv)
      command, config, files, help = Mint::Commandline.parse! argv

      if config.help || command.nil?
        puts help
        exit 0
      elsif command.to_sym == :publish
        begin
          Mint::Commandline.publish!(files, config: config)
        rescue ArgumentError => e
          $stderr.puts "Error: #{e.message}"
          exit 1
        end
      else
        possible_binary = "mint-#{command}"
        if File.executable? possible_binary
          system "#{possible_binary} #{argv[1..-1].join ' '}"
        else
          $stderr.puts "Error: Unknown command '#{command}'"
          exit 1
        end
      end
    end
  end
end