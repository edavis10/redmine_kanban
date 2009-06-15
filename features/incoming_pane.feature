Feature: Incoming Pane
  As I user
  I want to see the issues that have be entered in the Incoming pane
  So I know about recently reported issues

  Scenario: Display the oldest issues up to the limit
    Given the plugin is configured
    And I am logged in
    And there are "6" issues  with the "Unstaffed" status
    And I am on the Kanban page

    Then I should see "5" issues in the "Incoming" pane
