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
    And there should be a select field to pick the role for the "Staff Requests" pane
    And there should be a select field to pick the project for the "Incoming" pane
    And I should see "5" project names in the incoming project selector

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
    
    
  Scenario: Changing the configuration
    Given I am an Administrator
    And there are the default issue statuses
    And there are "5" active projects
    And there are "3" roles
    And I am logged in
    And I am on the Kanban configuration page

    When I select the role for "staff_role"
    And I select the project for "incoming_project"
    And I select the "Unstaffed" issue status for "Incoming"
    And I fill in the "Incoming" limit with "10"
    And I select the "Selected" issue status for "Selected Requests"
    And I fill in the "Selected Requests" limit with "20"
    And I select the "Active" issue status for "Active"
    And I fill in the "Active" limit with "10"
    And I select the "Test-N-Doc" issue status for "Testing"
    And I fill in the "Testing" limit with "15"
    And I press "Apply"

    Then I am on the Kanban configuration page
    And the plugin shoud save my settings

