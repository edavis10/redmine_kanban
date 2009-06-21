def div_name_to_css(name)
  name.gsub(' ','-').downcase
end

Before do
  Sham.reset
end

Given /^I am on the (.*)$/ do |page_name|
  visit path_to(page_name)
end

Given /^the plugin is configured$/ do
  Given 'there are the default issue statuses'
  Given 'there are "5" active projects'
  Given 'there are "5" roles'

  Setting.plugin_redmine_kanban = {
    "incoming_project"=> Project.find(:last).id,
    "staff_role"=> Role.find(:last).id,
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
    }}
    
end

def reconfigure_plugin(configuration_change)
  Setting.plugin_redmine_kanban = Setting.plugin_redmine_kanban.merge(configuration_change)
end


Given /^the Incoming project is not configured$/ do
  Setting.plugin_redmine_kanban = Setting.plugin_redmine_kanban.merge({'incoming_project' => ''})
end

Given /^there is a user$/ do
  @user = User.make
end

Given /^I am logged in$/ do
  @current_user ||= User.make
  User.stubs(:current).returns(@current_user)
end

Given /^I am an Administrator$/ do
  @current_user = User.make(:administrator)
  Given "I am logged in"
end

Given /^there are "(\d*)" active projects$/ do |count|
  count.to_i.times do
    Project.make
  end

  @feature_tracker = Tracker.make(:name => 'Feature')

  Project.find(:all).each do |project|
    assign_tracker_to_project @feature_tracker, project
  end
end

Given /^there is a project named "(.*)"$/ do |project_name|
  project = Project.make(:name => 'Incoming')
  @feature_tracker ||= Tracker.make(:name => 'Feature')
  assign_tracker_to_project @feature_tracker, project
end

Given /^there are "(\d*)" roles$/ do |count|
  count.to_i.times do
    Role.make
  end
end

Given /^there are "(\d*)" issues with the "(.*)" status$/ do |count, status_name|
  project =  make_project_with_trackers
  issue_status = IssueStatus.find_by_name(status_name)
  tracker = project.trackers.first

  count.to_i.times do
    Issue.make(:project => project, :status => issue_status, :tracker => tracker)
  end
end

Given /^there are "(\d*)" issues with the "(.*)" status and "(.*)" priority$/ do |count, status_name, priority_name|
  @project =  make_project_with_trackers if @project.nil?
  issue_status = IssueStatus.find_by_name(status_name)
  tracker = @project.trackers.first
  priority = IssuePriority.find_by_name(priority_name)
  priority = IssuePriority.make(:name => priority_name) if priority.nil?
  
  count.to_i.times do
    Issue.make(:project => @project, :status => issue_status, :tracker => tracker, :priority => priority)
  end
end

Given /^there are the default issue statuses$/ do
  IssueStatus.make(:name => 'New')
  IssueStatus.make(:name => 'Unstaffed')
  IssueStatus.make(:name => 'Selected')
  IssueStatus.make(:name => 'Active')
  IssueStatus.make(:name => 'Test-N-Doc')
  IssueStatus.make(:name => 'Closed', :is_closed => true)
  IssueStatus.make(:name => 'Rejected', :is_closed => true)
end

Given /^"(.*)" is configured as the "Incoming" project$/ do |project_name|
  reconfigure_plugin({'incoming_project' => Project.find_by_name(project_name)})
end


When /^I select the role for "staff_role"$/ do
  role = Role.find(:last)
  When 'I select "' + role.name + '" from "settings[staff_role]"'
end

When /^I select the project for "incoming_project"$/ do
  project = Project.find(:last)
  When 'I select "' + project.name + '" from "settings[incoming_project]"'
end

When /^I select the "(.*)" issue status for "(.*)"$/ do |staus_name, pane_name|
  issue_status = IssueStatus.find_by_name(staus_name)
  assert issue_status
  select_field = "settings[panes][#{div_name_to_css(pane_name)}][status]"
  When 'I select "' + issue_status.name + '" from "' + select_field + '"'
end

When /^I fill in the "(.*)" limit with "(\d*)"$/ do |pane_name, limit|
  limit_field = "settings[panes][#{div_name_to_css(pane_name)}][limit]"
  When 'I fill in "' + limit_field + '" with "' + limit + '"'
end

When /^I drag and drop an issue from "(.*)" to "(.*)"$/ do |from, to|
  @issue = Issue.find(:first, :conditions => {:status_id => IssueStatus.find_by_name('New')})
  
  request_page(url_for(:controller => 'kanbans', :action => 'update'),
               :put,
               {
                 :issue_id => @issue.id,
                 :from => div_name_to_css(from),
                 :to =>  div_name_to_css(to)
               })
end

Then /^I should see a "top" menu item called "(.*)"$/ do |name|
  assert_select("div#top-menu") do
    assert_select("a", name)
  end
end

Then /^I should see an? "(.*)" column$/ do |column_name|
  assert_select("#kanban") do
    assert_select("div##{div_name_to_css(column_name)}.column")
  end
end

Then /^I should see an? "(.*)" pane in "(.*)"$/ do |pane_name, column_name|
  assert_select("#kanban") do
    assert_select("div##{div_name_to_css(column_name)}.column") do
      assert_select("div##{div_name_to_css(pane_name)}.pane")
    end
  end
end

Then /^I should not see an? "(.*)" pane in "(.*)"$/ do |pane_name, column_name|
  assert_select("#kanban") do
    assert_select("div##{div_name_to_css(column_name)}.column") do
      assert_select("div##{div_name_to_css(pane_name)}.pane", :count => 0)
    end
  end
end

Then /^I should see an? "(.*)" column in "(.*)"$/ do |inner_column_name, column_name|
  assert_select("#kanban") do
    assert_select("div##{div_name_to_css(column_name)}.column") do
      assert_select("div##{div_name_to_css(inner_column_name)}.column")
    end
  end
end

Then /^I should see a "Configure" link for "Kanban"$/ do
  assert_select("a[href=?]",
               url_for(:controller => 'settings', :action => 'plugin', :id => 'redmine_kanban', :only_path => true),
                "Configure")
end

Then /^there should be a select field to pick the status for the "(.*)" pane$/ do |pane_name|
  assert_select("select[name=?]","settings[panes][#{div_name_to_css(pane_name)}][status]")
end

Then /^there should be a text field to enter the item limit for the "(.*)" pane$/ do |pane_name|
  assert_select("input[type=text][name=?]","settings[panes][#{div_name_to_css(pane_name)}][limit]")
end

Then /^there should be a select field to pick the role for the "Staff Requests" pane$/ do
  assert_select("select[name=?]","settings[staff_role]")
end

Then /^there should be a select field to pick the project for the "Incoming" pane$/ do
  assert_select("select[name=?]","settings[incoming_project]")
end

Then /^I should see "(\d*)" project names in the incoming project selector$/ do |count|
  assert_select("select[name=?]","settings[incoming_project]") do
    # +1 because there is a blank option to disable incoming
    assert_select("option", :count => (count.to_i + 1))
  end
end

Then /^the plugin should save my settings$/ do
  settings = Setting['plugin_redmine_kanban']

  assert_equal Role.find(:last).id, settings['staff_role'].to_i

  assert_equal(IssueStatus.find_by_name("New").id,
               settings['panes']['incoming']['status'].to_i)
  assert_equal("10", settings['panes']['incoming']['limit'])

  assert_equal(IssueStatus.find_by_name("Unstaffed").id,
               settings['panes']['backlog']['status'].to_i)
  assert_equal("25", settings['panes']['backlog']['limit'])

  assert_equal("25", settings['panes']['quick-tasks']['limit'])

  assert_equal(IssueStatus.find_by_name("Selected").id,
               settings['panes']['selected-requests']['status'].to_i)
  assert_equal("20", settings['panes']['selected-requests']['limit'])

  assert_equal(IssueStatus.find_by_name("Active").id,
               settings['panes']['active']['status'].to_i)
  assert_equal("10", settings['panes']['active']['limit'])

  assert_equal(IssueStatus.find_by_name("Test-N-Doc").id,
               settings['panes']['testing']['status'].to_i)
  assert_equal("15", settings['panes']['testing']['limit'])
end

Then /^I should see "(\d*)" issues in the "(.*)" pane$/ do |count, pane_name|
  assert_select("div##{div_name_to_css(pane_name)}.pane") do
    assert_select("li.issue", :count => count.to_i)
  end
end

Then /^I should see a "(.*)" group with "(\d*)" issues$/ do |group, count|
  assert_select("ol.#{div_name_to_css(group)}") do
    assert_select("li.issue", :count => count.to_i)
  end
end

Then /^the "(.*)" pane should refresh$/ do |pane|
  # no-op since this is done via HTML and not JavaScript
end

Then /^a successful message should be displayed$/ do
  assert_match /updated/i, flash[:notice]
end

Then /^the issue should be on the "(.*)" pane now$/ do |pane_name|
  assert @issue, "No @issue set"
  @issue.reload
  status_id = Setting['plugin_redmine_kanban']['panes'][div_name_to_css(pane_name)]['status']
  assert_equal status_id, @issue.status_id
end


Then /^there should be a user$/ do
  assert_equal 1, User.count(:conditions => {:login => @user.login})
end
