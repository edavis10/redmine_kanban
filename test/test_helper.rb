# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require 'faker'

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

module KanbanTestHelper
  def make_issue_statuses
    @new_status = IssueStatus.find_by_name('New') || IssueStatus.generate!(:name => 'New')
    @unstaffed_status = IssueStatus.find_by_name('Unstaffed') || IssueStatus.generate!(:name => 'Unstaffed')
    @selected_status = IssueStatus.find_by_name('Selected') || IssueStatus.generate!(:name => 'Selected')
    @active_status = IssueStatus.find_by_name('Active') || IssueStatus.generate!(:name => 'Active')
    @testing_status = IssueStatus.find_by_name('Test-N-Doc') || IssueStatus.generate!(:name => 'Test-N-Doc')
    @finished_status = IssueStatus.find_by_name('Closed') || IssueStatus.generate!(:name => 'Closed', :is_closed => true)
    @canceled_status = IssueStatus.find_by_name('Rejected') || IssueStatus.generate!(:name => 'Rejected', :is_closed => true)
    @hidden_status = IssueStatus.find_by_name('Closed Hide') || IssueStatus.generate!(:name => 'Closed Hide', :is_closed => true)
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
      Member.generate!({:principal => user, :project => @public_project, :roles => [role]})
      @users << user
    end
  end

  def make_project
    incoming_project = Project.generate!(:name => 'Incoming project')
    tracker = Tracker.generate!(:name => 'Feature')
    incoming_project.trackers << tracker
    incoming_project.save!

    return incoming_project
  end

  def make_kanban_role
    @kanban_role = Role.find_by_name('KanbanRole')
    @kanban_role = Role.generate!(:name => 'KanbanRole', :permissions => [:view_issues]) if @kanban_role.nil?
    @kanban_role
  end

  def make_management_group
    @management_group ||= Group.find_by_lastname('Kanban Management') || Group.generate!(:lastname => 'Kanban Management')
  end

  def configure_plugin(configuration_change = {})
    make_issue_statuses
    make_kanban_role
    make_management_group

    incoming_hidden_priority = (hidden = IssuePriority.find_by_name("Hidden")) ? hidden.id.to_s : nil
    incoming_hidden_project = (hidden = Project.find_by_name("Hidden")) ? hidden.id.to_s : nil
    
    Setting.plugin_redmine_kanban = {
    'user_help' => "*This is user help*",
    "staff_role"=> make_kanban_role.id,
    "management_group"=> @management_group.id.to_s,  
    "project_level" => "0",
    "panes"=>
    {
      "selected"=>{
        "status"=> @selected_status.id,
        "limit"=>"8"
      },
      "backlog"=>{
        "status"=> @unstaffed_status.id,
        "limit"=>"15"
      },
      "quick-tasks"=>{
        "limit"=>"5"
      },
      "testing"=>{
        "status"=> @testing_status.id,
        "limit"=>"5"
      },
      "active"=>{
        "status"=> @active_status.id,
        "limit"=>"5"
      },
      "incoming"=>{
        "status"=> @new_status.id,
        "limit"=>"5",
        "excluded_priorities"=> [incoming_hidden_priority],
        "excluded_projects"=> [incoming_hidden_project],  
        "url" => "/project/incoming/issues/new"
      },
      "finished"=>{
        "status"=> @finished_status.id,
        "limit"=>"7"
      },
      "canceled"=>{
        "status"=> @canceled_status.id,
        "limit" => '7'
      }
      }}.merge(configuration_change)

  end

  def reconfigure_plugin(configuration_change)
    Setting['plugin_redmine_kanban'] = Setting['plugin_redmine_kanban'].merge(configuration_change)
  end

  def setup_kanban_issues
    @private_project = Project.generate!(:is_public => false)
    @private_tracker = @private_project.trackers.first
    @public_project = Project.generate!(:is_public => true)
    @public_tracker = @public_project.trackers.first

    @hidden_project = Project.find_by_name('Hidden')
    @hidden_project ||= Project.generate!(:is_public => true, :name => 'Hidden')

    make_users
    
    high_priority
    medium_priority
    low_priority
    hidden_priority
  end

  def high_priority
    unless @high_priority
      @high_priority = IssuePriority.find_by_name("High")
      @high_priority ||= IssuePriority.generate!(:name => "High", :type => 'IssuePriority')
    end
    @high_priority
  end


  def medium_priority
    unless @medium_priority
      @medium_priority = IssuePriority.find_by_name("Medium")
      @medium_priority ||= IssuePriority.generate!(:name => "Medium", :type => 'IssuePriority')
    end
    @medium_priority
  end

  def low_priority
    unless @low_priority
      @low_priority = IssuePriority.find_by_name("Low")
      @low_priority ||= IssuePriority.generate!(:name => "Low", :type => 'IssuePriority')
    end
    @low_priority
  end

  def hidden_priority
    unless @priority_hidden_from_incoming
      @priority_hidden_from_incoming = IssuePriority.find_by_name("Hidden")
      @priority_hidden_from_incoming ||= IssuePriority.generate!(:name => "Hidden", :type => 'IssuePriority')
    end
    @priority_hidden_from_incoming

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
    # Incoming
    5.times do
      Issue.generate!(:tracker => @private_tracker,
                 :project => @private_project,
                 :status => @new_status)
    end

    6.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => @new_status)
    end
  end

  def setup_quick_issues
    # Quick tasks
    4.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => high_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => nil)
    end

    1.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => medium_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => nil)
    end

    2.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => low_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => nil)
    end

  end

  def setup_backlog_issues
    # Backlog tasks
    5.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => high_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => 5)
    end

    7.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => medium_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => 5)
    end

    5.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :priority => low_priority,
                 :status => @unstaffed_status,
                 :estimated_hours => 5)
    end

  end

  def setup_selected_issues
    # Selected tasks
    10.times do
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => @selected_status)
    end

  end

  def setup_active_issues
    # Active tasks
    @users.each do |user|
      5.times do
        Issue.generate_for_project!(@public_project,
                                    :tracker => @public_tracker,
                                    :assigned_to => user,
                                    :author => user,
                                    :status => @active_status)
      end
    end

  end
  
  def setup_testing_issues
    # Testing tasks
    @users.each do |user|
      5.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :assigned_to => user,
                   :status => @testing_status)
      end
    end

  end
  
  def setup_finished_issues
    # Finished tasks
    @users.each do |user|
      5.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :status => @finished_status,
                   :assigned_to => user)
      end

      # Extra issues that should not show up
      Issue.generate!(:tracker => @public_tracker,
                 :project => @public_project,
                 :status => @hidden_status,
                 :assigned_to => user)
    end

  end

  def setup_canceled_issues
    # Finished tasks
    @users.each do |user|
      2.times do
        Issue.generate!(:tracker => @public_tracker,
                   :project => @public_project,
                   :status => @canceled_status,
                   :assigned_to => user)
      end
    end

  end
    

  # Unknow user issues are KanbanIssues that should have a user
  # assigned but somehow didn't as the result of bad data.
  def setup_unknown_user_issues
    3.times do
      i = Issue.generate!(:tracker => @public_tracker,
                     :project => @public_project,
                     :assigned_to => nil,
                     :status => @active_status)
    end

    4.times do
      i = Issue.generate!(:tracker => @public_tracker,
                     :project => @public_project,
                     :assigned_to => nil,
                     :status => @testing_status)
    end
  end
end
include KanbanTestHelper

configure_plugin # Run it once now so each test doesn't need to run it

module IntegrationTestHelper
  def login_as(user="existing", password="existing")
    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'login'
    assert_response :success
    assert User.current.logged?
  end

  def visit_my_kanban_requests
    visit '/'
    click_link "My Requests"
      
    assert_response :success
    assert_equal "/kanban/my-requests", current_url
  end

  def visit_assigned_kanban
    visit '/'
    click_link "My Assignments"

    assert_response :success
    assert_equal "/kanban/my-assigned", current_url
  end
  
  def visit_kanban_board
    visit '/'
    click_link "Kanban"
      
    assert_response :success
    assert_equal "/kanban", current_url
  end

  # Cleanup current_url to remove the host; sometimes it's present, sometimes it's not
  def current_path
    return nil if current_url.nil?
    return current_url.gsub("http://www.example.com","")
  end

end

class ActionController::IntegrationTest
  include IntegrationTestHelper
end

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
