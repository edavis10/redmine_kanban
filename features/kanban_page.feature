Feature: Kanban Page
  As a user
  I want to see issues grouped according to Kanban
  So I know what to work on next

  Scenario: Kanban top menu item
    Given I am logged in
    And I am on the homepage
    Then I should see a "top" menu item called "Kanban"

  Scenario: Kanban columns
    Given the plugin is configured
    And I am logged in
    And I am on the Kanban page

    Then I should see an "Unstaffed Requests" column
    And I should see a "Selected Requests" column
    And I should see a "Staffed Requests" column

  Scenario: Kanban panes
    Given the plugin is configured
    And I am logged in
    And I am on the Kanban page

    Then I should see an "Incoming" pane in "Unstaffed Requests"
    And I should see a "Backlog" pane in "Unstaffed Requests"

    And I should see a "User" column in "Staffed Requests"
    And I should see an "Active" column in "Staffed Requests"
    And I should see a "Testing" column in "Staffed Requests"

    And I should see an "Active" pane for each user
    And I should see a "Testing" pane for each user
    And I should see a "Finished Requests" pane for each user
