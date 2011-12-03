Feature: Publish document with varying options at the command line
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

    And a file named "style.sass" with:
      """
      p
        margin: 0
      """

    And a file named "layout.haml" with:
      """
      %html
        %head
          %link(rel='stylesheet' href=stylesheet)

        %body
          #container= content
      """

  Scenario: Publish document with defaults
    When I run `mint publish content.md`
    Then a file named "content.md" should exist
    And a file named "content.html" should exist

  Scenario Outline: Publish document with named template, layout & style
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

  Scenario: Publish document with non-existent template
    When I run `mint publish -t nonexistent content.md`
    Then the stderr should contain "Template 'nonexistent' does not exist."

  Scenario: Publish document in directory
    When I run `mint publish content.md -d compiled`
    Then a file named "compiled/content.html" should exist

  Scenario: Publish document in subdirectory
    When I run `mint publish content.md -d compiled/chapter-1`
    Then a file named "compiled/chapter-1/content.html" should exist

  Scenario: Publish document with default style and explicit style destination
    When I run `mint publish content.md -n styles`
    Then a file named "styles/style.css" should exist

  Scenario: Publish document with hand-crafted style and explicit style destination
    When I run `mint publish content.md -n styles -s style.sass`
    Then a file named "styles/style.css" should exist

  Scenario: Publish document with hand-crafted layout
    When I run `mint publish content.md -l layout.haml`
    Then the file "content.html" should match /id=['"]container['"]/
