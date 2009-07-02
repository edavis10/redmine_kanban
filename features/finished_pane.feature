Feature: Finished Pane
  As I user
  I want to see the issues that have been completed for each user
  So I know who hase been finishing the most issues lately

  Scenario: Display the newest closed issues for the past 7 days
    Given the plugin is configured
    And I am logged in
    And there are "6" issues with the "Closed" status assigned to "John"
    And I am on the Kanban page

    Then I should see "6" issues in "John"s "Finished" pane

