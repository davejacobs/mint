Feature: Install, uninstall, and list templates
  As a writer
  I want to use existing stylesheets and install my own
  So that I do not have to clutter up my workspace with styles

  Background:
    Given a file named "file.sass" with:
      """
      p
        margin: 0
      """

    And a file named "file.scss" with:
      """
      p {
        margin: 0
      }
      """

    And a file named "file.haml" with:
      """
      %html
        %head
          %link(rel='stylesheet' href=stylesheet)

        %body
          #container= content
      """

    And a file named "file.erb" with:
      """
      <html>
        <head>
          <link rel='stylesheet' href=<%= stylesheet %> />
        </head>

        <body>
          <div id='container'>
            <%= content %>
          </div>
        </body>
      </html>
      """

  Scenario Outline: Install a named template with or without a name and scope
    When I run `mint install file.<ext> <dest template> <scope>`
    Then a file named "<root>/templates/<template>/<file name>" should exist

    Examples:
      | ext  | dest template | scope   | root    | template | file name   |
      | haml | -t pro        | --local | .mint   | pro      | layout.haml |
      | erb  | -t pro        | --local | .mint   | pro      | layout.erb  |
      | sass | -t pro        | --local | .mint   | pro      | style.sass  |
      | scss | -t pro        | --local | .mint   | pro      | style.scss  |
      | haml | -t pro        |         | .mint   | pro      | layout.haml |
      | haml |               |         | .mint   | file     | layout.haml |

  Scenario: Uninstall an installed file
    When I run `mint install -t pro file.sass`
    Then a directory named ".mint/templates/pro" should exist
    When I run `mint templates --local`
    Then the output should contain "pro"
    When I run `mint uninstall pro`
    Then a directory named ".mint/templates/pro" should not exist

  Scenario: List all templates in scope
    When I run `mint install -t one file.sass --local`
    When I run `mint install -t two file.sass --local`
    And I run `mint templates --local`
    Then the output should contain:
      """
      one
      two
      """
    When I run `mint templates one --local`
    Then the output should contain:
      """
      one
      """
