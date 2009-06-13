Feature: Configuration Panel
  As an administrator
  I want to be able to configure the plugin
  So it will work with how I setup my Redmine

  Scenario: Configuration link
    Given I am an Administrator
    And I am logged in
    And I am on the plugin administration page
    Then I should see a "Configure" link for "Kanban"

  Scenario: Configuration
    Given I am an Administrator
    And there are "5" active projects
    And I am logged in
    And I am on the plugin administration page

    When I follow "Configure"
    Then I am on the Kanban configuration page
    And I should see "Settings: Kanban"
    And I should see "General Settings"
    And I should see "Pane Settings"
    And there should be a select field to pick the status for the "Incoming" pane
    And there should be a select field to pick the status for the "Backlog" pane
    And there should be a select field to pick the status for the "Selected Requests" pane
    And there should be a select field to pick the status for the "Active" pane
    And there should be a select field to pick the status for the "Testing" pane

    And there should be a text field to enter the item limit for the "Incoming" pane
    And there should be a text field to enter the item limit for the "Backlog" pane
    And there should be a text field to enter the item limit for the "Selected Requests" pane
    And there should be a text field to enter the item limit for the "Active" pane
    And there should be a text field to enter the item limit for the "Testing" pane
    
    And I should see a select for Role for staffed requests
    And I should see a select for the incoming project
    And I should see "5" project names in the incoming project selector
    
