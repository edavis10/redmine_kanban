Feature: Incoming Pane
  As I user
  I want to see the issues that have be entered in the Incoming pane
  So I know about recently reported issues

  Scenario: Display the oldest issues up to the limit
    Given the plugin is configured
    And I am logged in
    And there are "6" issues with the "New" status
    And I am on the Kanban page

    Then I should see "5" issues in the "Incoming" pane

  Scenario: Move from Incoming to Backlog
    Given the plugin is configured
    And I am logged in
    And there are "6" issues with the "New" status
    And there are "5" issues with the "Unstaffed" status and "High" priority
    And there are "5" issues with the "Unstaffed" status and "Medium" priority
    And there are "5" issues with the "Unstaffed" status and "Low" priority
    And I am on the Kanban page

    When I drag and drop an issue from "Incoming" to "Backlog"

    Then the "Incoming" pane should refresh
    And the "Backlog" pane should refresh
    And a successful message should be displayed
    And the issue should be on the "Backlog" pane now
