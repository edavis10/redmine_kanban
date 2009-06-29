Feature: Staffed Panes
  As I user
  I want to see the issues that are staffed
  So I know which issues I need to work on

  Scenario: Display a list of Active issues
    Given the plugin is configured
    And I am logged in
    And there are "5" issues with the "Active" status assigned to "John"
    And I am on the Kanban page

    Then I should see "5" issues in "John"s "Active" pane

  Scenario: Display a list of Testing issues
    Given the plugin is configured
    And I am logged in
    And there are "5" issues with the "Testing" status assigned to "John"
    And I am on the Kanban page

    Then I should see "5" issues in "John"s "Testing" pane

