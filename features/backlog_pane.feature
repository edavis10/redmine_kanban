Feature: Backlog Pane
  As I user
  I want to see the issues that are unstaffed
  So I know which important issues to do next

  Scenario: Display a list of issues
    Given the plugin is configured
    And I am logged in
    And there are "35" issues with the "Unstaffed" status
    And I am on the Kanban page

    Then I should see "15" issues in the "Backlog" pane

  Scenario: Group Backlog by Issue Priority
    Given the plugin is configured
    And I am logged in
    And there are "3" issues with the "Unstaffed" status and "High" priority
    And there are "5" issues with the "Unstaffed" status and "Medium" priority
    And there are "10" issues with the "Unstaffed" status and "Low" priority
    And I am on the Kanban page

    Then I should see "15" issues in the "Backlog" pane
    And I should see a "High" group with "3" issues in the "Backlog" pane
    And I should see a "Medium" group with "5" issues in the "Backlog" pane
    And I should see a "Low" group with "7" issues in the "Backlog" pane

