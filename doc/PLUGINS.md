Plugins
-------

Overview
========

Mint is small, in the spirit of Unix. I want it to be extensible via a plugin architecture. This is an exploration of how I want that architecture to work.

I have two competing goals to balance:

- Mint should provide value and some degree of consistency to any 
  plugins that choose to integrate with it.
- Plugins should not have to follow a hierarchical or class-heavy architecture 
  to work out of the box.
- It would be nice if plugins could be written in any language, if they didn't want to
  have control over pre-rendered doc and other features only available to a Ruby script.

Ideas
=====

1. **The lightweight option: Bash interpolation.** `mint epub publish 
   file --option1 --option2` calls `mint-epub publish file --option2`
   and consumes `option1`.

2. **The callback option (mainly implemented).** `mint epub publish 
   file --option1 --option2` calls `mint publish` with the ePub plugin,
   passing in option2 with opts. *This plugin must be in a 
   ~/.mint/plugins directory.* (There will be other plugin directories 
   for other scopes.)

3. **The hacky option.** `mint epub publish file --option1 --option2`
   calls `mint` and searches $PATH for all mint-prefixed scripts.
   It then loads the named one and calls Mint.publish! with that 
   plugin specified.

It seems like option 2 is the best one. However, it defeats my goal of wanting a lightweight plugin system.

Questions
=========

1. What if the plugin defines a parameter that's named the same as a mint one?

Thoughts
========

1. I need to figure out how to give wrapped read/write access to the config file, in a standard "config namespace".

Plugin ideas
============

The following are some ideas I have for Mint plugins. I want plugins to be related to Mint's functionality, but not limited to desktop publishing.

    gem install mint-code
    gem install mint-doc
    gem install mint-epub
    gem install mint-footnotes
    gem install mint-share

### Mint code ###

For syntax highlighting:

    mint code install ruby
    mint code install ruby --color dark

Needs to be able to:

- ON INSTALL: Store Javascript files in its own plugin resources folder
- ON CODE INSTALL: Download code parsers and style from a server
- ON CODE INSTALL: Decide whether user wants all text to be pre-processed
  with this filter, and for Javascript to be injected
- ON INVOCATION: Install new Javascript highlighters and color schemes
- ON INVOCATION: Pass through extra filter. Use jQuery to dynamically
  inject Javascript into `<head/>` of layout

  OR could have convenience method "javascript" that could be used in
  views - this method could be overridden by plugin to provide whatever
  Javascript was necessary - perhaps based on what it found in the
  content file

Potential specification:

- Install callbacks: `before_install`, `after_install`
- Plugin directory for all scopes except gem scope: `plugins/code/
  (Do I need this? Probably so because the gem scope is going to be
  installed with the plugin, but no other folders will be, and I don't
  want to clutter up the space - but I will need to implement convenience
  methods for accessing these folders.)
- Render callbacks: `before\_render`, `after\_render`
- `javascript` convenience method available inside views - one which
  we can override to provide our own (based on analysis from `before\_render`)

### Mint ePub ###

For desktop ePub publishing:

    mint epub publish Minimalism.md

### Desktop to the Web ###

Mint is primarily meant to be a desktop publishing system for people who care about reusability. But I want it to know about the Web, too, because there are plenty of good publishing platforms online that you might want to take advantage of.

What if Mint were social and a good citizen with respect to data portability? If it let you create your documents once and upload to anywhere at any time with one command. This could look like:

    mint share YOUR_FILE --service YOUR_SERVICE --user YOUR_USERNAME

For example:
    
    mint share Minimalism.md --service crocodoc --user david

If you reuse the same publishing service and authentication details over and over again, it would be easy to set up the scheme in your mint config file:

    services:
      - crocodoc:
          host: crocodoc.com
          username: david
          authentication: password
          key: etc.

      - google-docs:
          host: docs.google.com
          username: david
          authentication: OpenId
          key: etc.

That way, your command could be something like:

    mint share Minimalism.md --service crocodoc

Examples of services could be Crocodoc and Google Docs. Examples of authentication providers could be Twitter, Facebook, and OpenId providers.

Or maybe a plugin could let you could publish multiple output formats, and to multiple locations:

    mint publish --service my-ftp --format html
    mint publish --blog personal

The configuration:

    services:
      - my-ftp:
          host: ftp.provider.com
          username: david
          security: sftp
          directory: /home/david/example.com/documents
      - my-blog:
        # ... etc., etc.
