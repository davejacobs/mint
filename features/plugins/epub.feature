Feature: Publish ePub document
  As a writer
  I want to create an ePub document at the command line from plain text
  So that I can publish books from style-free text

  Background:
    Given a file named "content.md" with:
      """
      Chapter 1
      =========

      This is a test. It is theoretically formatted in
      the Markdown templating language.

      Chapter 2
      =========

      This is a second chapter. 
      """

  Scenario: Publish document with defaults
    When I run `mint-epub publish content.md`
    Then a file named "content.epub" should exist
