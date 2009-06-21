Feature: Quick Tasks Pane
  As I user
  I want to see the top quick tasks
  So I can work on something quickly if I do not have much time

  Scenario: Display a list of issues
    Given the plugin is configured
    And I am logged in
    And there are "20" issues with the "Unstaffed" status
    And "15" issues that are "Unstaffed" are missing a time estimate
    And I am on the Kanban page

    Then I should see "15" issues in the "Quick Tasks" pane

  Scenario: Group Quick Tasks by Issue Priority
    Given the plugin is configured
    And I am logged in
    And there are "10" issues with the "Unstaffed" status and "High" priority
    And there are "5" issues with the "Unstaffed" status and "Medium" priority
    And there are "5" issues with the "Unstaffed" status and "Low" priority
    And "20" issues that are "Unstaffed" are missing a time estimate
    And I am on the Kanban page

    Then I should see "15" issues in the "Quick Tasks" pane
    And I should see a "High" group with "10" issues in the "Quick Tasks" pane
    And I should see a "Medium" group with "5" issues in the "Quick Tasks" pane

