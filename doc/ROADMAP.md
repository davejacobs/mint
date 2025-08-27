# Roadmap

## Get Mint working in 2025

- [x]: Make the library work again with latest Tilt and SassC
- [x]: Lock down versions
- [x]: Use ~/.config/mint/tmp for temporarily compiled stylesheets

## Tech cleanup

- [x]: Unify and simplify commandline_options and scope treatment
- [x]: Remove unnecessary indirection
- [x]: Explicit parameters
- [x]: Set all defaults early
- [ ]: Different flags for different commands, e.g., --force for edit-layout but not publish
- [ ]: Change to use Tilt Markdown Template instead of one-off Markdown renderer
- [ ]: Fix plugin system to work

## Build out core new features

- [x]: `mint publish` and `mint preview` (publish inlines CSS)
- [x]: --recursive
- [ ]: `mint export` command, to export styles to --user or --local for further editing
- [ ]: Live style updates
- [ ]: Digital garden support, including left-hand navigation & template
- [ ]: --index
- [ ]: Clean left-hand navigation for digital gardens
- [ ]: Great default layout & print sheet
- [ ]: EPub plugin
- [ ]: Theme vs. style split
- [ ]: Theme layering
- [ ]: Notebook plugin
- [ ]: Mint Doc plugin
- [ ]: CSS DSL
- [ ]: Live Reload plugin

## Documentation, testing, & tech debt

- [ ]: Get tests working again
- [x]: Use temporary files for compiling CSS & Sass
- [ ]: Use temporary files for compiling Haml
- [ ]: Document and clean up CSS file for document-like styles
- [ ]: Rationalize data flow, working style
- [ ]: Make sure live reload can work while developing sylesheet
- [ ]: Clarify relationship to plugins

## Great default layout

- [ ]: Responsive
- [ ]: Great print sheet

## Features

- [ ]: Base styles
- [ ]: Ecosystem templates
- [ ]: Bootstrap templates
- [ ]: Publish ebooks using mint-epub
- [ ]: Print stylesheets
- [ ]: Create multi-stage pipelines for archival

## Documentation & testing

- [ ]: All library files are documented (casually but consistently)
- [ ]: All references in docs use HTML and CSS instead of Html and Css
- [ ]: All library documentation uses Yardoc syntax
- [ ]: Yardoc documentation is published online and linked to Github post-commit hook (GitHub Actions)
- [ ]: Yardoc documentation is well-linked online
- [ ]: Update/tighten up the docs
- [ ]: Extract bulk of README into separate doc
- [ ]: Clean up documentation
- [ ]: Document all methods and classes using Yardoc
- [ ]: Simplify core code paths
- [ ]: All tests use FakeFS or equivalent instead of relying on the /tmp directory
- [ ]: Complete, simple, consistent testing

## Plugin system

- [ ]: Plugin architecture
- [ ]: Clarify where plugins live
- [ ]: Define template inheritance for plugins
- [ ]: mint-doc & unoconv integration

## Templates & styling

- [ ]: Default templates
- [ ]: Easy CSS syntax
- [ ]: Base CSS and expanded CSS
- [ ]: Built out all templates

## Ideas & future features

### Publishing ecosystem

- [ ]: Build versioned resume system with Mint (branches for different roles, companies, mail merge)
- [ ]: Wikipedia content integration (drag/drop images, text, quotes into books)
- [ ]: Mint protocol for standardized publishing flows
- [ ]: Multi-stage pipelines for archival

### User interface

- [ ]: GUI for documents with linking capabilities
- [ ]: Atom Shell/Electron editor
- [ ]: Google Docs integration for publishing/downloading

## Icebox

- [ ]: Make all options used in publish! command (even with merge)
- [ ]: Figure out how to tell if there's metadata (or add flag)
- [ ]: Refactor as much as possible into resources
- [ ]: Let Layouts have stylesheets
- [ ]: Refactor binary architecture
- [ ]: Add Notebook specs
- [ ]: Don't require "md" at end of names
- [ ]: Work better with Unix splats
- [ ]: Fix iframe issues, display issues, zooming
- [ ]: Let more than one style be used
- [ ]: Document name, merge, notebook handling
- [ ]: Clean up notebook functionality
- [ ]: Clarify multi files vs single files handling
- [ ]: Lock down dependency versions

