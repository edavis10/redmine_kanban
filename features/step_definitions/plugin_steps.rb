Given /^there is a user$/ do
  @user = User.make
end

Then /^there should be a user$/ do
  assert_equal 1, User.count(:conditions => {:login => @user.login})
end
