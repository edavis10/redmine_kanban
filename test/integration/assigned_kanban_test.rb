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
      click_link "My Assignments"
      
      assert_response :success
      assert_equal "/kanban/my-assigned", current_url

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

    context "load swimlanes using ajax" do

      setup do
        login_as
      end
      
      should "load the new requests lane" do
        @new_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @new_status)
        @new_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @new_status)
        @different_assigned_to_new_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @new_status)
        8.times do
          Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @new_status)
        end

        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @new_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user       
        
        visit "/kanban/assigned-to/#{@user.id}.js?column=incoming"
        doc = HTML::Document.new(response.body)
        
        # New lane
        assert_select doc.root, "#incoming-issues-user-#{@user.id}-project-0.incoming-issues" do
          assert_select "li#issue_#{@new_issue1.id}", :count => 1
          assert_select "li#issue_#{@new_issue2.id}", :count => 1
          assert_select "li#issue_#{@different_assigned_to_new_issue.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
          assert_select "li", :count => 5 # Filled to issue limit
        end
      end
      
      should "load the testing lane" do
        @testing_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
        @testing_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
        @different_assigned_to_testing_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @testing_status)

        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @testing_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/assigned-to/#{@user.id}.js?column=testing&project=#{@project.id}"
        doc = HTML::Document.new(response.body)
        
        # Testing lane
        assert_select doc.root, "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
          assert_select "li#issue_#{@testing_issue1.id}", :count => 1
          assert_select "li#issue_#{@testing_issue2.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
        end
        assert_select "li#issue_#{@different_assigned_to_testing_issue.id}", :count => 0
      end
      
      should "load the active lane" do
        @active_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
        @active_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
        @different_assigned_to_active_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @active_status)

        # Not a member but assigned
        @another_project = Project.generate!
        @non_member_issue = Issue.generate_for_project!(@another_project, :assigned_to => @user, :status => @active_status)

        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @active_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/assigned-to/#{@user.id}.js?column=active&project=#{@project.id}"
        doc = HTML::Document.new(response.body)
        
        # Active lane
        assert_select doc.root, "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
          assert_select "li#issue_#{@active_issue1.id}", :count => 1
          assert_select "li#issue_#{@active_issue2.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
        end
        assert_select "li#issue_#{@different_assigned_to_active_issue.id}", :count => 0

        # Don't show an issue assigned to a non-member (e.g. issue assigned and then moved)
        assert_select "#active-issues-user-#{@user.id}-project-#{@another_project.id}.active-issues", :count => 0 do
          assert_select "li#issue_#{@non_member_issue.id}", :count => 0
        end
      end
      
      should "load the selected lane" do
        @selected_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @selected_status)
        @different_assigned_to_selected_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @selected_status)

        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @selected_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/assigned-to/#{@user.id}.js?column=selected&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        # Selected lane
        assert_select doc.root, "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
          assert_select "li#issue_#{@selected_issue1.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
        end
        assert_select "li#issue_#{@different_assigned_to_selected_issue.id}", :count => 0
      end

      should "load the backlog lane" do
        @backlog_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @unstaffed_status, :estimated_hours => 5)
        @different_assigned_to_backlog_issue1 = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @unstaffed_status, :estimated_hours => 5)
        15.times do
          Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @unstaffed_status, :estimated_hours => 5, :priority => low_priority)
        end

        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @unstaffed_status, :estimated_hours => 5)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user
        
        visit "/kanban/assigned-to/#{@user.id}.js?column=backlog&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        # Backlog lane
        assert_select doc.root, "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
          assert_select "li#issue_#{@backlog_issue1.id}", :count => 1
          assert_select "li#issue_#{@different_assigned_to_backlog_issue1.id}", :count => 1
          assert_select "li", :count => 15 # Filled to issue limit
        end
      end
      

      should "load the finished lane" do
        @finished_issue = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @finished_status)
        @different_assigned_to_finished_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @finished_status)
        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @finished_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/assigned-to/#{@user.id}.js?column=finished&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        # Finished lane
        assert_select doc.root, "#finished-issues-user-#{@user.id}-project-#{@project.id}.finished-issues" do
          assert_select "li#issue_#{@finished_issue.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
        end
        assert_select "li#issue_#{@different_assigned_to_finished_issue.id}", :count => 0
      end
      

      should "load the canceled lane" do
        @canceled_issue = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @canceled_status)
        @different_assigned_to_canceled_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @canceled_status)
        @watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @canceled_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/assigned-to/#{@user.id}.js?column=canceled&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        # Canceled lane
        assert_select doc.root, "#canceled-issues-user-#{@user.id}-project-#{@project.id}.canceled-issues" do
          assert_select "li#issue_#{@canceled_issue.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 0
        end
        assert_select "li#issue_#{@different_assigned_to_canceled_issue.id}", :count => 0
      end
    end
    
    should_show_deadlines(:assigned) { visit_assigned_kanban }
    should_allow_overriding_the_incoming_pane_link_when_linked_to_a_project { visit_assigned_kanban }
  end

  context "for logged in users in the management group" do
    setup do
      @user = User.generate_with_protected!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing')
      @project = Project.generate!
      @role = Role.generate!(:permissions => [:view_issues, :view_kanban])
      Member.generate!({:principal => @user, :project => @project, :roles => [@role]})
      @management_group.users << @user
    end

    context "switch user" do
      should "allow showing another user's User Kanban page" do
        @another_user = User.generate_with_protected!.reload
        Issue.generate_for_project!(@project, :assigned_to => @another_user)
        
        login_as
        visit_assigned_kanban

        assert_select "div.contextual" do
          assert_select "form#user_switch"
        end

        select @another_user.to_s, :from => "Switch Assignee"
        submit_form "user_switch" # JS submission

        assert_response :success
        assert_equal "/kanban/assigned-to/#{@another_user.id}", current_path

        assert_select "#content", :text => /#{@another_user.to_s}'s Assignments/
      end

      should "only show users who have issues assigned to them" do
        @user1_with_issue = User.generate_with_protected!
        @user2_with_issue = User.generate_with_protected!
        @user_without_issue = User.generate_with_protected!

        Issue.generate_for_project!(@project, :assigned_to => @user1_with_issue)
        Issue.generate_for_project!(@project, :assigned_to => @user2_with_issue)

        login_as
        visit_assigned_kanban

        assert_select "div.contextual" do
          assert_select "form#user_switch" do
            assert_select "option[value=?]", @user1_with_issue.id
            assert_select "option[value=?]", @user2_with_issue.id
            assert_select "option[value=?]", @user_without_issue.id, :count => 0
          end
          
        end
        
      end
      
    end
  end
end
