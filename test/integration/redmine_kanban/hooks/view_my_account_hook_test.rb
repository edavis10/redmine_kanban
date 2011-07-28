require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineKanban::Hooks::ViewMyAccountTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#view_my_account" do
    setup do
      configure_plugin
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      login_as
    end

    should "allow changing the user's Kanban pane order" do
      click_link "My account"
      check "Reverse Kanban pane order"
      click_button "Save"
      
      assert_response :success
      assert_equal true, @user.reload.pref.kanban_reverse_pane_order # check it's forced to bool
      assert KanbanPane.pane_order_reversed?
    end
  end
end
