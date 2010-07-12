require 'test_helper'

class MyRequestsTest < ActionController::IntegrationTest
  def setup
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
      @another_user = User.generate_with_protected!
    end

    should "show a link to the main Kanban" do
      login_as
      visit_my_kanban_requests

      assert_select "a", :text => "Kanban Board"
    end

    should "not allow showing another user's User Kanban page" do
      login_as
      visit_my_kanban_requests

      assert_select "form#user_switch", :count => 0

      # Visit by url hacking
      visit "/kanban/users/#{@another_user.id}"
      assert_response :forbidden
      assert_template 'common/403'

    end
      
  end

  context "for logged in users in the management group" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})
      @management_group.users << @user
    end

    should "allow showing another user's User Kanban page" do
      @another_user = User.generate_with_protected!
      
      login_as
      visit_my_kanban_requests

      assert_select "div.contextual" do
        assert_select "form#user_switch"
      end

      select @another_user.to_s, :from => "Switch User"
      submit_form "user_switch" # JS submission

      assert_response :success
      assert_equal "/kanban/users/#{@another_user.id}", current_path

      assert_select "#content", :text => /#{@another_user.to_s}'s Kanban Requests/
    end
    
      
  end
end
