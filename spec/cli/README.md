# Mint CLI Test Suite

This directory contains a comprehensive test suite for the Mint command-line interface.

## Test structure

### Core test files

- **`argument_parsing_spec.rb`** - Tests command-line argument parsing and option handling
- **`template_management_spec.rb`** - Tests template installation, uninstallation, editing, and listing
- **`publish_workflow_spec.rb`** - Tests markdown publishing, file discovery, and output generation
- **`configuration_management_spec.rb`** - Tests configuration setting, reading, and scope management
- **`bin_integration_spec.rb`** - Tests actual `bin/mint` executable integration
- **`full_workflow_integration_spec.rb`** - End-to-end workflow tests for common user scenarios

### Support files

- **`../support/cli_helpers.rb`** - Helper methods for CLI testing (temp directories, file creation, output capture)
- **`run_cli_tests.rb`** - Custom test runner with better output formatting

## Running tests

### Run all CLI tests

```bash
# Using custom runner (recommended)
spec/run_cli_tests.rb

# Using RSpec directly
rspec spec/cli/ --format documentation
```

### Run specific test suites

```bash
# Individual test suites
spec/run_cli_tests.rb argument_parsing
spec/run_cli_tests.rb template_management
spec/run_cli_tests.rb publish_workflow

# Or with RSpec
rspec spec/cli/argument_parsing_spec.rb
```

### Run integration tests only

```bash
rspec spec/cli/full_workflow_integration_spec.rb
```

## Helper methods

The `cli_helpers.rb` provides utilities for:

```ruby
# Temporary directories
in_temp_dir do |dir|
  # Test code runs in isolated temp directory
end

# Output capture
stdout, stderr = capture_output do
  Mint::CommandLine.some_method
end

# File creation
create_markdown_file("test.md", "# Content")
create_template_directory("custom", with_layout: true)

# Command execution
result = run_command("mint", "publish", "file.md")

# Content verification
verify_file_content("output.html") do |content|
  expect(content).to include("expected text")
end
```

## Debugging failed tests

### Common issues
1. **Missing templates** - Tests create minimal templates; check `create_template_directory`
2. **File paths** - All paths should be relative within temp directory
3. **Configuration** - Use `setup_basic_config` to establish minimal config

### Debug helpers

```ruby
# Print current directory contents
puts Dir.glob("**/*")

# Print file contents
puts File.read("problematic.html") rescue "FILE NOT FOUND"

# Print configuration
puts YAML.load_file(".mint/config.yaml") rescue "NO CONFIG"
```

This test suite provides comprehensive coverage of Mint's CLI functionality while being maintainable and fast to run.