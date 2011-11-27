Plugins
-------

Mint is small, in the spirit of Unix. I want it to be extensible via a plugin architecture. This is an exploration of how I want that architecture to work.

I have two competing goals to balance:

- Mint should provide value and some degree of consistency to any 
  plugins that choose to integrate with it.
- Plugins should not have to follow a hierarchical or class-heavy architecture 
  to work out of the box.

With those goals in mind, my plugin system is going to work like this:

  mint PLUGIN several named files --option1 param --option2 param

Mint will parse what it can (the options it cares about).

And give your plugin (which is in a file named mint-{plugin-name} somewhere in your PATH, probably as a 'binary' distributed with a gem) this:

  documents = [Document.new('several'), 
               Document.new('named'),
               Document.new('documents')]

  options = { option1: param, option2: param }
  config = { option1: param, option2: param }

Potential problem: Mint wants to give its plugins access to full Mint documents, with possible callbacks, etc., for customizability of those documents. However, to build those documents, it needs its own options from the commandline. I could simply pass on any unused parameters to the plugins but there are three problems:

1. What if the plugin defines a parameter that's named the same as a mint one?
2. I'm not sure I can figure out with commandline words are filenames and which are parameters that Mint doesn't know about.
3. I'm not sure how customizable the parameters would be for downstream Mint plugins. Optparse, for example, needs to know what option flags you're looking for in order to parse them. Plugins have no way of specifying that.

I need to also figure out how to give wrapped read/write access to the config file, in a standard "config namespace".

So far, I know a plugin will need to have access to:

- Preprocess callback (to split up or modify file if desired)
- Commandline options
- Config options (both universal and plugin-specific)
- Access to any documents that are created

Plugin ideas
------------

The following are some ideas I have for Mint plugins. I want plugins to be related to Mint's functionality, but not limited to desktop publishing.

    gem install mint-code
    gem install mint-doc
    gem install mint-epub
    gem install mint-share

### Mint code ###

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

- `mint epub publish Minimalism.md`

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

### Bringing it together ###

This document is inconsistent because I have a lot of competing goals
desgining this plugin system.

How do I want to build a plugin?

- Build a full-fledged gem with its own bin, lib, 
  templates directories. Install via `gem install`

- Put a mint-prefixed executable file on my PATH. Expect templates, etc.,
  to be generated into a directory -- global or user level. This puts
  undue burden on plugin designer to generate templates from a code file.
  Probably not good.

- Some plugins are prepackaged and come with Mint. I have the option
  of including more plugins in the default install, if they're good
  plugins. Mint should provide an infrastructure for deciding whether
  a plugin is a default plugin or not and delegating directories
  appropriately.

### Intellectual property plugins ###

Or you could connect to a service to protect your intellectual property rights:

    mint copyright

I don't know if this is even possible, but wouldn't it be cool to generate a unique number based on the date, time, and contents of any article published and assign it to the article as a hash of all its metadata. The number would be so complex that you could not generate it without all the appropriate data. And using all the appropriate metadata (including date) would give the same number every time. But somehow, the algorithm would have to never run after the current date, so that potential plagiarists could not figure out what the hash should be for a date previous to the date you published it. That idea needs work, but I feel like maybe it could work out, probably as a separate service.
