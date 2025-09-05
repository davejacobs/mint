.PHONY: build install bump-minor clean test gallery help

help:
	@echo "Available targets:"
	@echo "  build       - Build the gem"
	@echo "  install     - Build and install the gem locally"
	@echo "  bump-minor  - Bump the minor version and build"
	@echo "  clean       - Remove built gem files"
	@echo "  gallery     - Generate all markdown files with all templates"
	@echo "  help        - Show this help message"

build:
	gem build mint.gemspec

install: build
	@version=$$(ruby -e "require './lib/mint/version'; puts Mint::VERSION") && \
	cd .. && gem install mint/mint-$$version.gem && cd -

bump-minor:
	@echo "Current version: $$(ruby -e "require './lib/mint/version'; puts Mint::VERSION")"
	@ruby -i -pe '$$_.gsub!(/VERSION = "(\d+)\.(\d+)\.(\d+)"/) { "VERSION = \"#{$$1}.#{$$2.to_i + 1}.0\"" }' lib/mint/version.rb
	@echo "New version: $$(ruby -e "require './lib/mint/version'; puts Mint::VERSION")"
	@$(MAKE) build

test:
	@rbenv rehash && spec/run_cli_tests.rb

gallery:
	@echo "Generating gallery with all templates..."
	@for template in config/templates/*/; do \
		template_name=$$(basename "$$template"); \
		echo "Processing template: $$template_name"; \
		find examples -name "*.md" -type f | while read -r md_file; do \
			output_file=$${md_file%.md}-$$template_name.html; \
			echo "  $$md_file -> $$output_file"; \
			bin/mint publish "$$md_file" --template "$$template_name" --style-mode original --output-file "$$output_file"; \
		done; \
	done
	@echo "Gallery generation complete!"

clean:
	rm -f *.gem