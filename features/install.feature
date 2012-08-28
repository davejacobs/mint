Feature: Publish document with varying options at the command line
  As a writer
  I want to create a document at the command line from plain text
  So that I can view a typeset version in a web browser

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

      # Not yet confirmed to be valid expectations
      | haml | -t pro        |         | .mint   | pro      | layout.haml |
      | haml |               |         | .mint   | file     | layout.haml |
