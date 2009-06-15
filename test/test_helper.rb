# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require 'faker'

Rails::Initializer.run do |config|
  config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com"
  config.gem "notahat-machinist", :lib => "machinist", :source => "http://gems.github.com"
end

require 'blueprints/blueprint'

module KanbanTestHelper
  def make_issue_statuses
    IssueStatus.make(:name => 'New')
    IssueStatus.make(:name => 'Unstaffed')
    IssueStatus.make(:name => 'Selected')
    IssueStatus.make(:name => 'Active')
    IssueStatus.make(:name => 'Test-N-Doc')
    IssueStatus.make(:name => 'Closed', :is_closed => true)
    IssueStatus.make(:name => 'Rejected', :is_closed => true)
  end

  def make_roles(count = 5)
    count.times do
      Role.make
    end
  end

  def make_project
    incoming_project = Project.make(:name => 'Incoming project')
    tracker = Tracker.make(:name => 'Feature')
    assign_tracker_to_project tracker, incoming_project

    return incoming_project
  end
  
  def configure_plugin(configuration_change = {})
    make_issue_statuses
    make_roles

    Setting.plugin_redmine_kanban = {
    "staff_role"=> Role.find(:last),
    "panes"=>
    {
      "selected-requests"=>{
        "status"=> IssueStatus.find_by_name('Selected').id,
        "limit"=>"8"
      },
      "backlog"=>{
        "status"=> IssueStatus.find_by_name('Unstaffed').id,
        "limit"=>"15"
      },
      "testing"=>{
        "status"=> IssueStatus.find_by_name('Test-N-Doc').id,
        "limit"=>"5"
      },
      "active"=>{
        "status"=> IssueStatus.find_by_name('Active').id,
        "limit"=>"5"
      },
      "incoming"=>{
        "status"=> IssueStatus.find_by_name('New').id,
        "limit"=>"5"
      }
      }}.merge(configuration_change)

  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_redmine_kanban'] = Setting['plugin_redmine_kanban'].merge(configuration_change)
  end
end
include KanbanTestHelper
