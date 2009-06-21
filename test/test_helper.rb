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
    IssueStatus.make(:name => 'New') if IssueStatus.find_by_name('New').nil?
    IssueStatus.make(:name => 'Unstaffed') if IssueStatus.find_by_name('Unstaffed').nil?
    IssueStatus.make(:name => 'Selected') if IssueStatus.find_by_name('Selected').nil?
    IssueStatus.make(:name => 'Active') if IssueStatus.find_by_name('Active').nil?
    IssueStatus.make(:name => 'Test-N-Doc') if IssueStatus.find_by_name('Test-N-Doc').nil?
    IssueStatus.make(:name => 'Closed', :is_closed => true) if IssueStatus.find_by_name('Closed').nil?
    IssueStatus.make(:name => 'Rejected', :is_closed => true) if IssueStatus.find_by_name('Rejected').nil?
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
      "quick-tasks"=>{
        "limit"=>"5"
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

  # Sets up a variety of issues to be used for the tests
  def setup_kanban_issues
    @private_project = make_project_with_trackers(:is_public => false)
    @public_project = make_project_with_trackers(:is_public => true)

    high_priority = IssuePriority.make(:name => "High")
    medium_priority = IssuePriority.make(:name => "Medium")
    low_priority = IssuePriority.make(:name => "Low")

    # Incoming
    5.times do
      Issue.make(:tracker => @private_project.trackers.first,
                 :project => @private_project,
                 :status => IssueStatus.find_by_name('New'))
    end

    6.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :status => IssueStatus.find_by_name('New'))
    end

    # Quick tasks
    4.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => high_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => nil)
    end

    1.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => medium_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => nil)
    end

    2.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => low_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => nil)
    end

    # Backlog tasks
    5.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => high_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => 5)
    end

    7.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => medium_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => 5)
    end

    5.times do
      Issue.make(:tracker => @public_project.trackers.first,
                 :project => @public_project,
                 :priority => low_priority,
                 :status => IssueStatus.find_by_name('Unstaffed'),
                 :estimated_hours => 5)
    end

  end
end
include KanbanTestHelper
