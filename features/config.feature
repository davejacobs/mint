Feature: Change and view stored configuration
  As a writer
  I want to configure sensible defaults for different project scopes
  So that I do not have to repeatedly configure my tool

  Background:
    Given a directory named ".mint"
    And a file named ".mint/defaults.yaml" with:
      """
      layout: zen
      """

  Scenario: View aggregated configuration
    When I run `mint config`
    Then the output should contain "layout: zen"

  Scenario: Configure a local default
    When I run `mint set layout default`
    And I run `mint config`
    Then the output should contain "layout: default"
    And the output should not contain "layout: zen"
