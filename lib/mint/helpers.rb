require "pathname"
require "tempfile"
require "yaml"
require "active_support/core_ext/string/inflections"

module Mint
  module Helpers
    # Preserves relative path to root
    #
    # @param [Pathname] root the root directory
    # @param [Pathname] source the source file path
    # @param [Pathname] destination the destination directory
    # @return [Pathname] the relative path to the destination
    def reorient_relative_path(root, source, destination)
      source_path = Pathname.new(source).expand_path
      root_path = Pathname.new(root).expand_path
      relative_path = source_path.relative_path_from(root_path)
      relative_dir = relative_path.dirname
      
      if relative_dir.to_s != "."
        base_destination = destination || ""
        if base_destination.empty?
          destination = relative_dir.to_s
        else
          destination = File.join(base_destination, relative_dir.to_s)
        end
      end
      
      destination
    end

    # Returns the relative path to to_directory from from_directory.
    # If to_directory and from_directory have no parents in common besides
    # /, returns the absolute directory of to_directory. Assumes no symlinks.
    #
    # @param [Pathname] to_directory the target directory
    # @param [Pathname] from_directory the starting directory
    # @return [Pathname] the relative path to to_directory from
    #   from_directory, or an absolute path if they have no parents in common
    #   other than /
    def self.normalize_path(to_directory, from_directory)
      to_path, from_path = [to_directory, from_directory].map {|d| d.expand_path }
      to_root, from_root = [to_path, from_path].map {|p| p.each_filename.first }
      to_root == from_root ?
        to_path.relative_path_from(from_path) :
        to_path
    end

    # Transforms Markdown links from .md extensions to .html for cross-linking between documents.
    #
    # @param [String] text the markdown text containing links
    # @return [String] the text with transformed links
    def self.transform_markdown_links(text, output_file_format: "%{basename}.%{new_extension}", new_extension: "html")
      text.gsub(/(\[([^\]]*)\]\(([^)]*\.md)\))/) do |match|
        link_text = $2
        link_url = $3
        
        # Only transform relative links (not absolute URLs)
        if link_url !~ /^https?:\/\//
          # Preserve directory structure in links
          dirname = File.dirname(link_url)
          basename = File.basename(link_url, ".*")
          
          new_filename = output_file_format % {
            basename: basename,
            original_extension: "md",
            new_extension: new_extension
          }
          
          new_url = if dirname == "."
            new_filename
          else
            File.join(dirname, new_filename)
          end
          
          "[#{link_text}](#{new_url})"
        else
          match
        end
      end
    end

    def self.format_output_file(file, new_extension: "html", format_string: "%{basename}.%{new_extension}")
      basename = File.basename(file, ".*")
      original_extension = File.extname(file)[1..-1] || ""
      format_string % {
        basename: basename,
        original_extension: original_extension,
        new_extension: new_extension
      }
    end

    # Resolves the output file path for a source file, handling preserve_structure logic
    #
    # @param [Pathname, String] source_file the source file path
    # @param [Config] config the configuration object containing preserve_structure and other options
    # @return [String] the relative path from destination_directory to the output file
    def self.resolve_output_file_path(source_file, config)
      source_path = Pathname.new(source_file)
      
      if config.preserve_structure
        relative_path = source_path.relative_path_from(config.working_directory) rescue source_path
        destination_file_basename = format_output_file(relative_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
        
        if relative_path.dirname.to_s == "."
          destination_file_basename
        else
          File.join(relative_path.dirname.to_s, destination_file_basename)
        end
      else
        format_output_file(source_path.basename.to_s, new_extension: "html", format_string: config.output_file_format)
      end
    end

    # Creates relative navigation links from one file to another
    #
    # @param [String] from_file_path the path to the file that will contain the link
    # @param [String] to_file_path the path to the file being linked to  
    # @param [Config] config the configuration object
    # @return [Pathname] relative path from from_file to to_file
    def self.relative_link_between_files(from_file_path, to_file_path, config)
      from_output_path = resolve_output_file_path(from_file_path, config)
      to_output_path = resolve_output_file_path(to_file_path, config)
      
      from_pathname = Pathname.new(from_output_path)
      to_pathname = Pathname.new(to_output_path)
      
      # Calculate relative path from the directory containing from_file to to_file
      from_dir = from_pathname.dirname
      to_pathname.relative_path_from(from_dir)
    end
  end
end
