# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require 'faker'

Rails::Initializer.run do |config|
  config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com"
  config.gem "notahat-machinist", :lib => "machinist", :source => "http://gems.github.com"
end

require File.expand_path(File.dirname(__FILE__) + '/blueprints/blueprint')

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

  def make_users(count = 3)
    role = Role.find(:last)
    @users = []
    count.times do
      user = User.make
      make_member({:user => user, :project => @public_project}, [role])
      @users << user
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
    Role.make(:name => 'KanbanRole') if Role.find_by_name('KanbanRole').nil?

    Setting.plugin_redmine_kanban = {
    "staff_role"=> Role.find(:last),
    "panes"=>
    {
      "selected"=>{
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
      },
      "finished"=>{
        "status"=> IssueStatus.find_by_name('Closed').id
      }
      }}.merge(configuration_change)

  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_redmine_kanban'] = Setting['plugin_redmine_kanban'].merge(configuration_change)
  end

  # Sets up a variety of issues to be used for the tests
  def setup_kanban_issues
    @private_project = make_project_with_trackers(:is_public => false)
    @private_tracker = @private_project.trackers.first
    @public_project = make_project_with_trackers(:is_public => true)
    @public_tracker = @public_project.trackers.first

    make_users
    
    @high_priority = IssuePriority.make(:name => "High") if IssuePriority.find_by_name("High").nil?
    @medium_priority = IssuePriority.make(:name => "Medium") if IssuePriority.find_by_name("Medium").nil?
    @low_priority = IssuePriority.make(:name => "Low") if IssuePriority.find_by_name("Low").nil?

  end

  def setup_all_issues
    setup_incoming_issues
    setup_quick_issues
    setup_backlog_issues
    setup_selected_issues
    setup_active_issues
    setup_testing_issues
    setup_finished_issues
  end
  
  def setup_incoming_issues
    new_status = IssueStatus.find_by_name('New')
    # Incoming
    5.times do
      Issue.make(:tracker => @private_tracker,
                 :project => @private_project,
                 :status => new_status)
    end

    6.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => new_status)
    end
  end

  def setup_quick_issues
    unstaffed_status = IssueStatus.find_by_name('Unstaffed')
    # Quick tasks
    4.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @high_priority,
                 :status => unstaffed_status,
                 :estimated_hours => nil)
    end

    1.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @medium_priority,
                 :status => unstaffed_status,
                 :estimated_hours => nil)
    end

    2.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @low_priority,
                 :status => unstaffed_status,
                 :estimated_hours => nil)
    end

  end

  def setup_backlog_issues
    unstaffed_status = IssueStatus.find_by_name('Unstaffed')
    # Backlog tasks
    5.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @high_priority,
                 :status => unstaffed_status,
                 :estimated_hours => 5)
    end

    7.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @medium_priority,
                 :status => unstaffed_status,
                 :estimated_hours => 5)
    end

    5.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @low_priority,
                 :status => unstaffed_status,
                 :estimated_hours => 5)
    end

  end

  def setup_selected_issues
    selected_status = IssueStatus.find_by_name('Selected')
    # Selected tasks
    10.times do
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => selected_status)
    end

  end

  def setup_active_issues
    active_status = IssueStatus.find_by_name('Active')
    # Active tasks
    @users.each do |user|
      5.times do
        Issue.make(:tracker => @public_tracker,
                   :project => @public_project,
                   :assigned_to => user,
                   :status => active_status)
      end
    end

  end
  
  def setup_testing_issues
    testing_status = IssueStatus.find_by_name('Test-N-Doc')
    # Testing tasks
    @users.each do |user|
      5.times do
        Issue.make(:tracker => @public_tracker,
                   :project => @public_project,
                   :assigned_to => user,
                   :status => testing_status)
      end
    end

  end
  
  def setup_finished_issues
    closed_status = IssueStatus.find_by_name('Closed')
    rejected_status = IssueStatus.find_by_name('Rejected')

    # Finished tasks
    @users.each do |user|
      5.times do
        Issue.make(:tracker => @public_tracker,
                   :project => @public_project,
                   :status => closed_status,
                   :assigned_to => user)
      end

      # Extra issues that should not show up
      Issue.make(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => rejected_status,
                 :assigned_to => user)
    end

  end
end
include KanbanTestHelper

configure_plugin # Run it once now so each test doesn't need to run it


class Test::Unit::TestCase
  def self.should_allow_state_change_from(starting_state, options = {:to => nil, :using => :nothing})
    should "allow the change from #{starting_state} to #{options[:to]} using #{options[:using]}" do
      assert @object, "No @object set"
      @object.state = starting_state
      assert @object.save, "Failed to save object"
      @object.send(options[:using].to_sym)
      assert_equal options[:to], @object.state
    end


  end
end
