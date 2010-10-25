require 'test_helper'

class AssignedKanbanTest < ActionController::IntegrationTest
  def setup
    configure_plugin
    setup_kanban_issues
  end

  context "for anonymous users" do
    should "require login" do
      visit "/kanban/my-assigned"
      
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
      click_link "Assigned Kanban"
      
      assert_response :success
      assert_equal "/kanban/my-assigned", current_url

    end
    
    should "not show a link to the main Kanban" do
      login_as
      visit_assigned_kanban

      assert_select "a", :text => "Kanban Board", :count => 0
    end
  end

  context "for logged in users with permission to View Kanban" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})
      Member.generate!({:principal => @user, :project => @public_project, :roles => [@role]})
      @another_user = User.generate_with_protected!
    end

    should "show a link to the main Kanban" do
      login_as
      visit_assigned_kanban

      assert_select "a", :text => "Kanban Board"
    end

    should "show the user help content using the text formatting" do
      login_as
      visit_assigned_kanban

      assert_select '.user-help' do
        assert_select 'strong', :text => 'This is user help'
      end
    end

    should "not allow showing another user's User Kanban page" do
      login_as
      visit_assigned_kanban

      assert_select "form#user_switch", :count => 0

      # Visit by url hacking
      visit "/kanban/assigned-to/#{@another_user.id}"
      assert_response :forbidden
      assert_template 'common/error'

    end

  end
end
