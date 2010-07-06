require 'test_helper'

class MyRequestsTest < ActionController::IntegrationTest
  setup do
    configure_plugin
    setup_kanban_issues
  end

  context "for anonymous users" do
    should "require login" do
      visit "/kanban/my-requests"
      
      assert_response :success
      assert_match /login/, current_url
    end
  end

  context "for logged in users without permission to View Kanban" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
    end
    
    should "load their own page" do
      login_as
      click_link "My Kanban Requests"
      
      assert_response :success
      assert_equal "/kanban/my-requests", current_url

    end
    
    should "not show a link to the main Kanban" do
      login_as
      visit_my_kanban_requests

      assert_select "a", :text => "Kanban Board", :count => 0
    end
  end

  context "for logged in users with permission to View Kanban" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})
    end

    should "show a link to the main Kanban" do
      login_as
      visit_my_kanban_requests

      assert_select "a", :text => "Kanban Board"
    end
  end

  context "for logged in users with permission to Manage Kanban" do
    should "allow showing another user's User Kanban page"
  end
end
