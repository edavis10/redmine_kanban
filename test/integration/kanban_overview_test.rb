require 'test_helper'

class KanbanOverviewTest < ActionController::IntegrationTest
  def setup
    configure_plugin
    setup_kanban_issues
    Setting.plugin_redmine_kanban['panels']['overview']['subissues_take_higher_priority'] = '0'
  end

  context "for anonymous users" do
    should "require login" do
      visit "/kanban/overview"
      
      assert_response :success
      assert_match /login/, current_url
    end
  end

  context "for logged in users without permission to View Kanban" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
    end
    
    should "require login" do
      login_as
      visit "/kanban/overview"

      assert_response 403
    end
  end

  context "for logged in users with permission to View Kanban" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing').reload
      @project = Project.generate!.reload
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role, Role.find_by_name('KanbanRole')]})
      Member.generate!({:principal => @user, :project => @public_project, :roles => [@role, Role.find_by_name('KanbanRole')]})
      @another_user = User.generate_with_protected!.reload
      Member.generate!({:principal => @another_user, :project => @project, :roles => [@role, Role.find_by_name('KanbanRole')]})

    end

    should "show the user help content using the text formatting" do
      login_as
      visit_kanban_overview

      assert_select '.user-help' do
        assert_select 'strong', :text => 'This is user help'
      end
    end

    context "showing the swimlanes" do
      should "be separated by project" do
        login_as
        visit_kanban_overview

        assert_select "#kanban div.project-lane.horizontal-lane", :text => /#{@project.name}/i
      end
      
      should "have a row for each project's user" do
        login_as
        visit_kanban_overview

        assert_select "#kanban div.horizontal-lane" do
          assert_select "div.project-#{@project.id} .user-name", :text => /#{@user.name}/i
          assert_select "div.project-#{@project.id} .user-name", :text => /#{@another_user.name}/i

          assert_select "div.project-#{@public_project.id} .user-name", :text => /#{@user.name}/i
        end
      end

    end

    context "load the swimlanes using ajax" do
      setup do
        login_as
      end

      should "load the testing lane" do
        @testing_issue_medium = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status, :priority => medium_priority)
        @testing_issue_high = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status, :priority => high_priority)

        visit "/kanban/overview.js?column=testing&project=#{@project.id}&user=#{@user.id}"
        doc = HTML::Document.new(response.body)
        
        # Testing lane
        assert_select doc.root, "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
          assert_select "li#issue_#{@testing_issue_high.id}", :count => 1
          assert_select "li#issue_#{@testing_issue_medium.id}", :count => 0
        end
      end

      should "load the active lane" do
        @active_issue_medium = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status, :priority => medium_priority)
        @active_issue_high = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status, :priority => high_priority)

        visit "/kanban/overview.js?column=active&project=#{@project.id}&user=#{@user.id}"
        doc = HTML::Document.new(response.body)
        
        # Active lane
        assert_select doc.root, "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
          assert_select "li#issue_#{@active_issue_high.id}", :count => 1
          assert_select "li#issue_#{@active_issue_medium.id}", :count => 0
        end
      end

      should "load the selected lane" do
        @selected_issue_medium = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @selected_status, :priority => medium_priority)
        @selected_issue_high = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @selected_status, :priority => high_priority)

        visit "/kanban/overview.js?column=selected&project=#{@project.id}&user=#{@user.id}"
        doc = HTML::Document.new(response.body)

        # Selected lane
        assert_select doc.root, "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
          assert_select "li#issue_#{@selected_issue_high.id}", :count => 1
          assert_select "li#issue_#{@selected_issue_medium.id}", :count => 0
        end
      end

      should "load the backlog lane" do
        @backlog_issue_medium = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @unstaffed_status, :estimated_hours => 5, :priority => medium_priority)
        @backlog_issue_high = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @unstaffed_status, :estimated_hours => 5, :priority => high_priority)
        
        visit "/kanban/overview.js?column=backlog&project=#{@project.id}&user=#{@user.id}"
        doc = HTML::Document.new(response.body)

        # Backlog lane
        assert_select doc.root, "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
          assert_select "li#issue_#{@backlog_issue_high.id}", :count => 1
          assert_select "li#issue_#{@backlog_issue_medium.id}", :count => 0
        end
      end

    end
    
    
  end
end
