require 'test_helper'

class NewIssueTest < ActionController::IntegrationTest
  def setup
    configure_plugin
    setup_kanban_issues
  end

  context "My Kanban Requests" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
    end

    context "for users who don't have permission to open a new issue" do
      should "not should a new issue link" do
        login_as
        visit_my_kanban_requests

        assert_select "a", :text => "New Issue", :count => 0
      end
    end
    
    context "for users who have permission to open a new issue" do
      should "show a link to open a new issue" do
        @project = Project.generate!
        @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :add_issues])
        Member.generate!({:principal => @user, :project => @project, :roles => [@role]})

        login_as
        visit_my_kanban_requests

        assert_select "a", :text => "New issue"
      end
      
    end
  end

  # Have to simulate JS requests by hitting the same endpoint as jQuery
  context "Loading the new issue form" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :add_issues])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})

      login_as
      visit_my_kanban_requests
    end
    
    should 'load the new issue form from the server' do
      get '/kanban_issues/new.js'

      assert_response :success
      assert_select "form#issue-form"
    end
    
    should 'have a select field to select the project'
  end

  
end
