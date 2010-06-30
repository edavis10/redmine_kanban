# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require 'faker'

module KanbanTestHelper
  def make_issue_statuses
    IssueStatus.generate!(:name => 'New') if IssueStatus.find_by_name('New').nil?
    IssueStatus.generate!(:name => 'Unstaffed') if IssueStatus.find_by_name('Unstaffed').nil?
    IssueStatus.generate!(:name => 'Selected') if IssueStatus.find_by_name('Selected').nil?
    IssueStatus.generate!(:name => 'Active') if IssueStatus.find_by_name('Active').nil?
    IssueStatus.generate!(:name => 'Test-N-Doc') if IssueStatus.find_by_name('Test-N-Doc').nil?
    IssueStatus.generate!(:name => 'Closed', :is_closed => true) if IssueStatus.find_by_name('Closed').nil?
    IssueStatus.generate!(:name => 'Rejected', :is_closed => true) if IssueStatus.find_by_name('Rejected').nil?
    IssueStatus.generate!(:name => 'Closed Hide', :is_closed => true) if IssueStatus.find_by_name('Closed Hide').nil?
  end

  def make_roles(count = 5)
    count.times do
      Role.generate!
    end
  end

  def make_users(count = 3)
    role = make_kanban_role
    @users = []
    count.times do
      user = User.generate_with_protected!
      make_member({:principal => user, :project => @public_project}, [role])
      @users << user
    end
  end

  def make_project
    incoming_project = Project.generate!(:name => 'Incoming project')
    tracker = Tracker.generate!(:name => 'Feature')
    assign_tracker_to_project tracker, incoming_project

    return incoming_project
  end

  def setup_anonymous_role
    begin
      @anon_role = Role.anonymous
    rescue
      @anon_role = Role.generate!
      @anon_role.update_attribute(:builtin, Role::BUILTIN_ANONYMOUS)
    end
  end

  def setup_non_member_role
    begin
      @anon_role = Role.non_member
    rescue
      @non_member_role = Role.generate!
      @non_member_role.update_attribute(:builtin, Role::BUILTIN_NON_MEMBER)
    end
  end

  def make_kanban_role
    role = Role.find_by_name('KanbanRole')
    role = Role.generate!(:name => 'KanbanRole', :permissions => [:view_issues]) if role.nil?
    role
  end

  def configure_plugin(configuration_change = {})
    setup_anonymous_role
    setup_non_member_role
    make_issue_statuses
    make_kanban_role

    Setting.plugin_redmine_kanban = {
    "staff_role"=> make_kanban_role.id,
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
        "status"=> IssueStatus.find_by_name('Closed').id,
        "limit"=>"7"
      },
      "canceled"=>{
        "status"=> IssueStatus.find_by_name('Rejected').id,
        "limit" => '7'
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
    
    @high_priority = IssuePriority.generate!(:name => "High", :type => 'IssuePriority') if IssuePriority.find_by_name("High").nil?
    @medium_priority = IssuePriority.generate!(:name => "Medium", :type => 'IssuePriority') if IssuePriority.find_by_name("Medium").nil?
    @low_priority = IssuePriority.generate!(:name => "Low", :type => 'IssuePriority') if IssuePriority.find_by_name("Low").nil?

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
      Issue.generate!(:tracker => @private_tracker,
                 :project => @private_project,
                 :status => new_status)
    end

    6.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => new_status)
    end
  end

  def setup_quick_issues
    unstaffed_status = IssueStatus.find_by_name('Unstaffed')
    # Quick tasks
    4.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @high_priority,
                 :status => unstaffed_status,
                 :estimated_hours => nil)
    end

    1.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @medium_priority,
                 :status => unstaffed_status,
                 :estimated_hours => nil)
    end

    2.times do
      Issue.generate!(:tracker => @public_tracker,
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
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @high_priority,
                 :status => unstaffed_status,
                 :estimated_hours => 5)
    end

    7.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => @medium_priority,
                 :status => unstaffed_status,
                 :estimated_hours => 5)
    end

    5.times do
      Issue.generate!(:tracker => @public_tracker,
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
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => selected_status)
    end

  end

  def setup_active_issues
    active_status = IssueStatus.find_by_name('Active')
    # Active tasks
    @users.each do |user|
      5.times do
        Issue.generate_for_project!(@public_project,
                                    :tracker => @public_tracker,
                                    :assigned_to => user,
                                    :author => user,
                                    :status => active_status)
      end
    end

  end
  
  def setup_testing_issues
    testing_status = IssueStatus.find_by_name('Test-N-Doc')
    # Testing tasks
    @users.each do |user|
      5.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :assigned_to => user,
                   :status => testing_status)
      end
    end

  end
  
  def setup_finished_issues
    closed_status = IssueStatus.find_by_name('Closed')
    hidden_status = IssueStatus.find_by_name('Closed Hide')

    # Finished tasks
    @users.each do |user|
      5.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :status => closed_status,
                   :assigned_to => user)
      end

      # Extra issues that should not show up
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => hidden_status,
                 :assigned_to => user)
    end

  end

  def setup_canceled_issues
    canceled_status = IssueStatus.find_by_name('Rejected')

    # Finished tasks
    @users.each do |user|
      2.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :status => canceled_status,
                   :assigned_to => user)
      end
    end

  end
    

  # Unknow user issues are KanbanIssues that should have a user
  # assigned but somehow didn't as the result of bad data.
  def setup_unknown_user_issues
    active_status = IssueStatus.find_by_name('Active')
    testing_status = IssueStatus.find_by_name('Test-N-Doc')
    3.times do
      i = Issue.generate!(:tracker => @public_tracker,
                     :project => @public_project,
                     :assigned_to => nil,
                     :status => active_status)
    end

    4.times do
      i = Issue.generate!(:tracker => @public_tracker,
                     :project => @public_project,
                     :assigned_to => nil,
                     :status => testing_status)
    end
  end


  # Extracted out of the Machinist files, might not be needed now
  #
  def make_project_with_enabled_modules(attributes = {})
    Project.generate!(attributes)
  end

  def make_project_with_trackers(attributes = {}, tracker_name = 'Feature')
    project = make_project_with_enabled_modules(attributes)
    tracker = Tracker.find_by_name(tracker_name)
    tracker = Tracker.generate!(:name => tracker_name) if tracker.nil?
    assign_tracker_to_project tracker, project
    project
  end

  def assign_tracker_to_project(tracker, project)
    project.trackers << tracker
    project.save!
  end

  def make_member(attributes, roles)
    Member.generate!(attributes.merge(:roles => roles))
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

  def self.should_not_raise_an_exception_if_the_settings_are_missing(&block)
    should "not raise an exception if the settings are missing" do
      Setting.plugin_redmine_kanban = {}

      assert_nothing_thrown do
        block.call
      end
    end
  end
end
