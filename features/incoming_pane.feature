Feature: Incoming Pane
  As I user
  I want to see the issues that have be entered in the Incoming pane
  So I know about recently reported issues

  Scenario: No Incoming project configured
    Given the plugin is configured
    And the Incoming project is not configured
    And I am logged in
    And I am on the Kanban page

    Then I should not see an "Incoming" pane in "Unstaffed Requests"

  Scenario: Display the oldest issues up to the limit
    Given the plugin is configured
    And I am logged in
    And there is a project named "Incoming"
    And "Incoming" is configured as the "Incoming" project
    And there are "6" issues in the "Incoming" project with the "Unstaffed" status
    And I am on the Kanban page

    Then I should see "5" issues in the "Incoming" pane
