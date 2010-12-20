require 'test_helper'

class ShowIssueTest < ActionController::IntegrationTest
  def setup
    @hidden_project = Project.generate!(:is_public => true, :name => 'Hidden')
    configure_plugin
    setup_kanban_issues
  end

  # Have to simulate JS requests by hitting the same endpoint as jQuery
  context "Loading the issue show form" do
    context "as a user with permission to view the issue" do
      setup do
        @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
        @project = Project.generate!
        @issue = Issue.generate_for_project!(@project)
        @journal = Journal.generate!(:issue => @issue, :user => @user, :notes => 'Test journal')
        @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :add_issues])
        Member.generate!({:principal => @user, :project => @project, :roles => [@role]})

        login_as
        visit_my_kanban_requests
      end
      
      should 'load the issue page from the server' do
        get "/kanban_issues/#{@issue.id}.js"

        assert_response :success

        doc = HTML::Document.new(response.body)
        assert_select doc.root, "#issue-#{@issue.id}"
      end

      should "show the issue attributes" do
        get "/kanban_issues/#{@issue.id}.js"

        assert_response :success

        doc = HTML::Document.new(response.body)
        assert_select doc.root, "table.attributes"
      end

      should "show the history" do
        get "/kanban_issues/#{@issue.id}.js"

        assert_response :success

        doc = HTML::Document.new(response.body)
        assert_select doc.root, "#history" do
          assert_select "div.journal", :count => 1
        end
        
      end
    end
    
    context "as a user without permission to view the issue" do
      setup do
        @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
        @project = Project.generate!
        @issue = Issue.generate_for_project!(@project)
        @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :add_issues])

        login_as
        visit_my_kanban_requests
      end
      
      should 'not load the issue page from the server' do
        get "/kanban_issues/#{@issue.id}.js"

        assert_response :not_found
      end

    end
  end
end
