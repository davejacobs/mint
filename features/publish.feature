# This is a test of the mint binary. It only covers named templates 
# (layouts and styles) that are included with Mint or that are passed 
# in via relative path on document creation. Further testing might include:
#
# - MINT_PATH & scope selection
# - File configuration
# - Header parsing

Feature: Mint document with varying options at the command line
  As a writer
  I want to create a document at the command line from plain text
  So that I can view a typeset version in a web browser

  Background:
    Given a file named "content.md" with:
      """
      Header
      ======

      This is a test. It is theoretically formatted in
      the Markdown templating language.
      """
  Scenario: Mint document with defaults
    When I run `mint publish content.md`
    Then a file named "content.md" should exist
    And a file named "content.html" should exist

  Scenario Outline: Mint document with named template, layout & style
    # Note: For all rendering, we're assuming Tilt is doing its own testing.
    # Therefore, we're not testing anything except that our content made it
    # into our destination file.
    
    When I run `mint publish <template> <layout> <style> content.md`
    Then a file named "content.html" should exist
    And the file "content.html" should contain "This is a test"
    And a file named "<style file>" should exist
    And the file "content.html" should match /templates.*style.css/
    And the file "content.html" should contain "<style file>"

    Examples:
      | template | layout | style  | style file                            |
      |          |        |        | ../../templates/default/css/style.css |
      | -t pro   |        |        | ../../templates/pro/css/style.css     |
      |          | -l pro | -s pro | ../../templates/pro/css/style.css     |

  Scenario: Mint document with non-existent template
    When I run `mint publish -t nonexistent content.md`
    Then the stderr should contain "Template 'nonexistent' does not exist."
