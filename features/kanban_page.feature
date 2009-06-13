Feature: Kanban Page
  As a user
  I want to see issues grouped according to Kanban
  So I know what to work on next

  Scenario: Kanban top menu item
    Given I am logged in
    And I am on the homepage
    Then I should see a "top" menu item called "Kanban"

  Scenario: Kanban columns
    Given I am logged in
    And I am on the Kanban page

    Then I should see an "Unstaffed Requests" column
    And I should see a "Selected Requests" column
    And I should see a "Staffed Requests" column
    And I should see a "Finished Requests" column
