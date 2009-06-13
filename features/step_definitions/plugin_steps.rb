def div_name_to_css(name)
  name.gsub(' ','-').downcase
end

Before do
  Sham.reset
end

Given /^I am on the (.*)$/ do |page_name|
  visit path_to(page_name)
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
end

Given /^there are "(\d*)" roles$/ do |count|
  count.to_i.times do
    Role.make
  end
end

Given /^there are the default issue statuses$/ do
  IssueStatus.make(:name => 'Unstaffed')
  IssueStatus.make(:name => 'Selected')
  IssueStatus.make(:name => 'Active')
  IssueStatus.make(:name => 'Test-N-Doc')
  IssueStatus.make(:name => 'Closed', :is_closed => true)
  IssueStatus.make(:name => 'Rejected', :is_closed => true)
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

Then /^the plugin shoud save my settings$/ do
  settings = Setting['plugin_redmine_kanban']

  assert_equal Role.find(:last).id, settings['staff_role'].to_i
  assert_equal Project.find(:last).id, settings['incoming_project'].to_i

  assert_equal(IssueStatus.find_by_name("Unstaffed").id,
               settings['panes']['incoming']['status'].to_i)
  assert_equal("10", settings['panes']['incoming']['limit'])

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


Then /^there should be a user$/ do
  assert_equal 1, User.count(:conditions => {:login => @user.login})
end
