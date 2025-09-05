require 'open3'
require 'tmpdir'
require 'stringio'
require 'fileutils'
require 'ostruct'

module CLIHelpers
  # Capture stdout/stderr from a block
  def capture_output
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = stdout = StringIO.new
    $stderr = stderr = StringIO.new
    yield
    [stdout.string, stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  # Run a command and capture its output
  def run_command(env_or_command, *args)
    if env_or_command.is_a?(Hash)
      # First argument is environment variables
      env = env_or_command
      command = args.shift
      stdout, stderr, status = Open3.capture3(env, command, *args)
    else
      # First argument is the command
      command = env_or_command
      stdout, stderr, status = Open3.capture3(command, *args)
    end
    
    OpenStruct.new(
      stdout: stdout,
      stderr: stderr,
      status: status,
      success?: status.success?,
      exit_code: status.exitstatus
    )
  end

  # Create a temporary directory and run the block inside it
  def in_temp_dir
    Dir.mktmpdir("mint-test-") do |dir|
      old_dir = Dir.pwd
      Dir.chdir(dir)
      yield(dir)
    ensure
      Dir.chdir(old_dir) if old_dir
    end
  end

  # Create a sample markdown file with content
  def create_markdown_file(name = "test.md", content = "# Test\n\nHello world!")
    File.write(name, content)
    name
  end

  # Create a sample template file
  def create_template_file(name, type = :layout, content = nil)
    content ||= case type
                when :layout
                  "<!DOCTYPE html>\n<html><body><%= yield %></body></html>"
                when :style
                  "body { font-family: sans-serif; }"
                end
    
    File.write(name, content)
    name
  end

  # Create a complete template directory structure
  def create_template_directory(name, with_layout: true, with_style: true)
    template_dir = ".mint/templates/#{name}"
    FileUtils.mkdir_p(template_dir)
    
    if with_layout
      File.write("#{template_dir}/layout.erb", 
        "<!DOCTYPE html>\n<html><head><title>Test Document</title></head>" +
        "<body><%= content %></body></html>")
    end
    
    if with_style
      File.write("#{template_dir}/style.css", 
        "body { margin: 2em; font-family: sans-serif; }")
    end
    
    template_dir
  end

  # Verify file exists and has expected content
  def verify_file_content(file, expected_content = nil, &block)
    expect(File.exist?(file)).to be true
    content = File.read(file)
    if expected_content
      expect(content).to include(expected_content)
    end
    block.call(content) if block_given?
    content
  end

  # Clean up common files created during tests
  def cleanup_test_files(*patterns)
    patterns.each do |pattern|
      Dir.glob(pattern).each do |file|
        FileUtils.rm_rf(file)
      end
    end
  end

  # Set up a minimal mint configuration
  def setup_basic_config(scope = :local)
    config_dir = case scope
                 when :local then ".mint"
                 when :user then File.expand_path("~/.config/mint") 
                 when :global then "#{Mint::PROJECT_ROOT}/config"
                 end
    
    FileUtils.mkdir_p(config_dir)
    config_file = "#{config_dir}/config.yaml"
    
    basic_config = {
      'layout' => 'default',
      'style' => 'default',
      'destination' => nil
    }
    
    File.write(config_file, basic_config.to_yaml)
    config_file
  end

  # Mock editor for testing edit functionality
  def mock_editor(command = "true")  # Use 'true' instead of 'echo' to be silent
    original_editor = ENV['EDITOR']
    ENV['EDITOR'] = command
    yield
  ensure
    if original_editor
      ENV['EDITOR'] = original_editor
    else
      ENV.delete('EDITOR')
    end
  end

  # Suppress all output during test execution
  def silence_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  # Assert that a command would abort with specific message
  def expect_abort_with_message(message)
    expect { yield }.to raise_error(SystemExit) do |error|
      # Capture the abort message (this is a bit tricky with Ruby's abort)
      expect(error.message).to include(message) if error.message
    end
  end
end

RSpec.configure do |config|
  config.include CLIHelpers
end