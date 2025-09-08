require "tempfile"

require_relative "../config" 
require_relative "../workspace"

module Mint
  module Commandline
    # For each file specified, publishes a new file based on configuration.
    #
    # @param [Array] source_files files a group of filenames
    # @param [Config, Hash] config a Config object or Hash with configuration options
    def self.publish!(source_files, config: Config.new)
      config = Config.ensure_config(config)
      
      if source_files.empty?
        raise ArgumentError, "No files specified. Use file paths or '-' to read from STDIN."
      end
      
      if config.stdin_mode
        stdin_content = source_files.first
        temp_file = Tempfile.new(['stdin', '.md'])
        temp_file.write(stdin_content)
        temp_file.close
        
        workspace = Workspace.new([temp_file.path], config)
        workspace.publish!
        output_file = workspace.destination_path_for(temp_file.path)
        if config.verbose
          puts "Published: STDIN -> #{output_file}"
        end
        
        temp_file.unlink
      else
        workspace = Workspace.new(source_files, config)
        workspace.publish!
        if config.verbose
          source_files.each do |source_file|
            output_file = workspace.destination_path_for(source_file)
            puts "Published: #{source_file} -> #{output_file}"
          end
        end
      end
    end
  end
end