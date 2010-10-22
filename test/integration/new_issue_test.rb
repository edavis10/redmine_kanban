require 'test_helper'

class NewIssueTest < ActionController::IntegrationTest
  def setup
    @hidden_project = Project.generate!(:is_public => true, :name => 'Hidden')
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
      IssueStatus.generate!(:is_default => true)
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @incoming_project = Project.find_by_name("Hidden")
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :add_issues])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})
      @incoming_project_membership = Member.generate!({:principal => @user, :project => @incoming_project, :roles => [@role]})

      new_config = Setting['plugin_redmine_kanban']
      new_config["panes"]["incoming"].merge!("excluded_projects" => [@project.id.to_s, @incoming_project.id.to_s])
      Setting['plugin_redmine_kanban'] = new_config

      login_as
      visit_my_kanban_requests
    end
    
    should 'load the new issue form from the server' do
      get '/kanban_issues/new.js'

      assert_response :success

      doc = HTML::Document.new(response.body)
      assert_select doc.root, '#issue-form'
    end

    context "project select" do
      should 'have a select field to select the project when there are more than one' do
        get '/kanban_issues/new.js'

        assert_response :success

        doc = HTML::Document.new(response.body)
        assert_select doc.root, 'select' do
          assert_select 'option', :text => /#{@project.name}/
        end
        
      end

      should "have a hidden field for the project when there is only one" do
        assert @incoming_project_membership.destroy # Only one project allowed now
        
        get '/kanban_issues/new.js'

        assert_response :success

        doc = HTML::Document.new(response.body)
        assert_select doc.root, 'input[type=hidden]', :value => /#{@project.id}/

      end

    end
  end

  
end
