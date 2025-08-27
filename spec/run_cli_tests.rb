#!/usr/bin/env ruby

# CLI Test Runner for Mint
# Runs the comprehensive CLI test suite with better output formatting

require 'colorize'
require 'benchmark'

def run_test_suite(pattern, description)
  puts "\n#{'=' * 60}".cyan
  puts " #{description}".cyan.bold
  puts "#{'=' * 60}".cyan
  
  time = Benchmark.measure do
    system("rspec #{pattern} --format documentation --color")
  end
  
  puts "\n⏱️  Time: #{time.real.round(2)}s".yellow
  $?.success?
end

def main
  puts "🧪 Mint CLI Test Suite".green.bold
  puts "Running comprehensive CLI tests...\n"
  
  test_suites = [
    ["spec/cli/argument_parsing_spec.rb", "CLI Argument Parsing"],
    ["spec/cli/template_management_spec.rb", "Template Management"],  
    ["spec/cli/publish_workflow_spec.rb", "Publishing Workflows"],
    ["spec/cli/configuration_management_spec.rb", "Configuration Management"],
    ["spec/cli/bin_integration_spec.rb", "Binary Integration"],
    ["spec/cli/full_workflow_integration_spec.rb", "Full Workflow Integration"]
  ]
  
  results = []
  total_time = Benchmark.measure do
    test_suites.each do |pattern, description|
      if File.exist?(pattern)
        success = run_test_suite(pattern, description)
        results << { name: description, success: success }
      else
        puts "⚠️  Test file #{pattern} not found".yellow
        results << { name: description, success: false }
      end
    end
  end
  
  # Summary
  puts "\n#{'=' * 60}".cyan
  puts " TEST SUMMARY".cyan.bold  
  puts "#{'=' * 60}".cyan
  
  results.each do |result|
    status = result[:success] ? "✅ PASS".green : "❌ FAIL".red
    puts "#{status} #{result[:name]}"
  end
  
  passed = results.count {|r| r[:success] }
  total = results.size
  
  puts "\n📊 Results: #{passed}/#{total} test suites passed".cyan
  puts "⏱️  Total time: #{total_time.real.round(2)}s".yellow
  
  if passed == total
    puts "\n🎉 All CLI tests passed!".green.bold
    exit 0
  else
    puts "\n❌ Some CLI tests failed".red.bold
    exit 1
  end
end

# Run individual test suite if specified
if ARGV.length > 0
  test_name = ARGV[0]
  pattern = "spec/cli/#{test_name}*_spec.rb"
  
  matching_files = Dir.glob(pattern)
  if matching_files.empty?
    puts "❌ No test files found matching: #{pattern}".red
    puts "\nAvailable test suites:".yellow
    Dir.glob("spec/cli/*_spec.rb").each do |file|
      basename = File.basename(file, "_spec.rb")
      puts "  - #{basename}"
    end
    exit 1
  end
  
  matching_files.each do |file|
    description = File.basename(file, "_spec.rb").split('_').map(&:capitalize).join(' ')
    run_test_suite(file, description)
  end
else
  main
end