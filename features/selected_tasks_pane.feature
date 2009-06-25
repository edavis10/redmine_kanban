Feature: Selected Tasks Pane
  As I user
  I want to see the issues that the manager has selected
  So I know if there are more important issues to work on next

  Scenario: Display a list of issues
    Given the plugin is configured
    And I am logged in
    And there are "8" issues prioritized by the Manager
    And I am on the Kanban page

    Then I should see "8" issues in the "Selected Tasks" pane

