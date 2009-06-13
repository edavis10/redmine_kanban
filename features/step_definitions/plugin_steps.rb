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
  @current_user = User.make
  User.stubs(:current).returns(@current_user)
end

Then /^I should see a "top" menu item called "(.*)"$/ do |name|
  assert_select("div#top-menu") do
    assert_select("a", name)
  end
end

Then /^there should be a user$/ do
  assert_equal 1, User.count(:conditions => {:login => @user.login})
end
