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

Then /^there should be a user$/ do
  assert_equal 1, User.count(:conditions => {:login => @user.login})
end
