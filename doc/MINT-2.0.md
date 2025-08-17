# Mint 2.0

After 10+ years of software development experience, I want to simplify Mint and solve the hard problems rather than solving what is already solved.

## Use cases

- Archive plain text documents, with version control
- Easily change templates for published documents
- Share published documents with others
- Format and save articles in a format I like, subject to change over time

## Problems to solve

- Configuration of which style and layout should be used
- Package everything into one deliverable
- Pipeline with discrete stages of files in folders that can be archived
- Live linking
- Updating live links
- Viewing final files on iPhone, iPad, macOS
- ePubs
- Linked 'notebook' style of viewing files
- Live CSS editing
- Editing document styles using familiar language / syntax / concepts, not CSS

## Problems I'll outsource

- Templating
- Ecosystem of HTML and CSS themes, including typography
- Live editing

## Design

Core functionality:
- Gather the following:
  - Content
    - Provided by user
      - footnotes
      - side notes
      - images,
  - Layout HTML and CSS
    - Can be provided by user
    - Can come from Mint itself
    - Can come from local filesystem
  - Typographic style
    - Can be provided by user
    - Can come from Mint itself
    - Can come from local filesystem
  - JS
- Output:
  Combined content, layout, style
 
- how to view on phone?

<<<<<<< HEAD
=======

>>>>>>> a9a649e (Work in progress. Delete when merged.)
Plugins:
- Interface with... ?

Pipeline stages:
- Try bash script or Tekton?
