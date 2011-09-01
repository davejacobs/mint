Design considerations
=====================

Problem 1: Internal representation of files, external presentation, mutability
------------------------------------------------------------------------------

Three revealing questions and/or interests:

1. How do I represent files internally? I need to accommodate relative
   and absolute paths as input -- especially for source files, which
   should always accept an absolute path if the user wants to do so. Somehow
   I need to turn any possible user input into a canonical representation
   of that input.
   
2. What exactly does "canonical" mean for a Mint Document? One way of thinking
   about "canonical" is to think about storing user input as it is given.
   For example, a source file of "Content.md", "subdirectory/Content.md"
   and "/home/david/Content.md" all get stored as is. Any time we want to
   get another view of that path that depends on this "canonical" data,
   we build up that view from our constituent parts. This is useful to
   provide lazy evaluation of a path. However, it means we need to a) be
   careful to actually expand our path to an absolute one whenever necessary,
   and b) build up our pathname *outside* of our library every time we
   want to use it or access it through several (delegated?) virtual
   attributes. Canonical, more traditionally, means storing information
   as a single point source and exposing it as different views. For example,
   we could store our path as a Pathname and expose it as a string, basename,
   etc.

3. The third question is one of mutability. Should I let people change a
   document's root or source or destination after it has been initialized? If so,
   I will need to store each individual part separately, because refactoring
   a Pathname would be confusing, especially if we're allowing for symlink
   following and expanded paths.

If I am going to go with this store-segments-separately scheme, when do I
evaluate the root? I want to be able to change the root, but should I be
able to set a root on a document? Logically, does that even make sense? Or
does it get instantiated when I actually publish a document? Also, I need to
make sure I understand the relationship between a document's source and its root.

The simplest solution here *might* be to store all appropriate methods in
a Transformation module (with a source and destination path) that may 
or may not use delegation. The Transformation will store all appropriate
path pieces separately and will expose them individually as strings or
collectively (aggregated) into a path-like string or a pathname.

Now, what virtual attributes should I expose? (The more I expose, the more
I have to test.)

- root_directory              - root path (expanded: yes, unless lambda?)
- root_path                   - root path (expanded: yes)

- source                      - source path, relative or absolute 
                                (expanded: however user originally specified)
- source_file                 - lazy virtual attribute (expanded: yes, 
                                based on root: ?)
- source_file_path            - lazy virtual attribute (expanded: yes, 
                                based on root: ?)
- source_directory            - lazy virtual attribute based on source_file_path
                                (expanded: yes, based on root: ?)
- source_directory_path       - lazy virtual attribute based on source_file_path
                                (expanded: yes, based on root: ?)

- destination                 - destination path (expanded: no)
- destination_file            - lazy virtual attribute 
                                (expanded: yes, based on root: yes)
- destination_file_path       - lazy virtual attribute
                                (expanded: yes, based on root: yes)
- destination_directory       - lazy virtual attribute based on
                                destination_file_path
- destination_directory_path  - lazy virtual attribute based on
                                destination_file_path

Style destination is also stored as an attribute (like destination) and
is *not* delegated out to the document's style instance. Why not? Because
this is the easiest, most elegant way to handle edge cases where we do and
do not want to render a style to a destination relative to a document's root + destination. This kind of logic should belong to a document, and not its
style, which is really just a way to organize data.

- style_destination
- style_destination_file
- style_destination_file_path
- style_destination_directory
- style_destination_directory_path
