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
      Member.generate!({:principal => @user, :project => @public_project, :roles => [@role]})
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

    
    should "show the swimlanes" do
      @testing_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
      @testing_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
      @not_assigned_testing_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @testing_status)
      @active_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
      @active_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
      @not_assigned_active_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @active_status)

      
      login_as
      visit_my_kanban_requests

      # Testing lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#testing-issues-user-#{@user.id}.testing-issues" do
            assert_select "li#issue_#{@testing_issue1.id}", :count => 1
            assert_select "li#issue_#{@testing_issue2.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@not_assigned_testing_issue.id}", :count => 0
      
      # Active lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#active-issues-user-#{@user.id}.active-issues" do
            assert_select "li#issue_#{@active_issue1.id}", :count => 1
            assert_select "li#issue_#{@active_issue2.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@not_assigned_active_issue.id}", :count => 0
      
    end
    
    should "group each horizontal lane by project" do
      login_as
      visit_my_kanban_requests

      assert_select '#kanban' do
        assert_select 'div.project-lane' do
          assert_select '.project-name', :text => /#{@public_project.name}/
          assert_select '.project-name', :text => /#{@project.name}/
        end
      end
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
