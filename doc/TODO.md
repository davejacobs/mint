To do
-----

### Quick thoughts ###

- Refactor tests into consistent style, using variables
  only when appropriate
- Refactor /tmp directory manipulation in tests
- Add commandline tests
- Refactor commandline
- Add Cucumber features for commandline
- Add Yardoc
- Add "mint show (file)" command - so that you can easily delete templates
  you've created but don't want
- Add "mint edit --copy --layout default" option - so that you can edit a layout/style without modifying the original
- Three solid templates to begin with
- Modularize commands like git/rip (mint-edit, mint-install, etc.) and allow anyone to add new scripts by adding a mint-\* command to MINT\_PATH

- Add testing for file configuration
- Add scope testing?

- Add verbose output
- Allow user to set style destination file via style\_destination, by making
  common assumptions about what a file looks like

### Specific ###

- add unit testing, especially for all configuration precedence scenarios
- add logging
- build a solid repertoire of included templates
- parse metadata as DSL from source documents?
- add more convenience methods to expose this metadata in a layout
- add documentation
- build out a robust, loosely coupled binary
- create a useful simulation mode/commandline option
- create a system that promotes building on included CSS base designs  (for example via --base or --nobase options) so that users can tweak fonts, etc., without creating stylesheets - this will make Mint more accessible

### Design goals ###

- provide good defaults
- ensure that the library is flexible in an intuitive way
- ensure that templates are easy to add without touching the filesystem
- implement the plugin system

### The inline style DSL ###

I want to build a DSL people can use to get the same options they get from Word
to alter an existing style without knowing Css. This will involve typing a
config section at the top of a document to alter whatever stylesheet is applied
to that document (by including it inline).

What properties do people expect to be able to change?

- Font: [font name], [font size]
- Color: [font color]
- Margin: [document margin]
- Width: [document width]
- Line spacing: [line height for paragraphs] 
- Bullet: [bullet shape - even unicode?]
- Indentation: [indentation]
- After paragraph: [margin before paragraph]
- Before paragraph: [margin after paragraph]
- Smart typography: on
- Smart images: on

- Style:
  (Any CSS written here will be included verbatim in the document)
