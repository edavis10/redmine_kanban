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

    should "show the swimlanes based on issue assignment" do
      @new_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @new_status)
      @new_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @new_status)
      @different_assigned_to_new_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @new_status)

      @testing_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
      @testing_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @testing_status)
      @different_assigned_to_testing_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @testing_status)
      @active_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
      @active_issue2 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @active_status)
      @different_assigned_to_active_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @active_status)
      @selected_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @selected_status)
      @different_assigned_to_selected_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @selected_status)
      @backlog_issue1 = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @unstaffed_status, :estimated_hours => 5)
      @different_assigned_to_backlog_issue1 = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @unstaffed_status, :estimated_hours => 5)

      @finished_issue = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @finished_status)
      @different_assigned_to_finished_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @finished_status)
      @canceled_issue = Issue.generate_for_project!(@project, :assigned_to => @user, :status => @canceled_status)
      @different_assigned_to_canceled_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @canceled_status)
      
      # Not a member but assigned
      @another_project = Project.generate!
      @non_member_issue = Issue.generate_for_project!(@another_project, :assigned_to => @user, :status => @active_status)

      # Watched issues should not be shown
      @new_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @new_status)
      @testing_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @testing_status)
      @active_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @active_status)
      @selected_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @selected_status)
      @backlog_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @unstaffed_status, :estimated_hours => 5)
      @finished_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @finished_status)
      @canceled_watched_issue = Issue.generate_for_project!(@project, :assigned_to => @another_user, :status => @canceled_status)

      [@new_watched_issue, @testing_watched_issue, @active_watched_issue, @selected_watched_issue, @backlog_watched_issue, @finished_watched_issue, @canceled_watched_issue].each do |issue|
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => issue.id, :user => @user)
        assert issue.watched_by? @user
      end

      login_as
      visit_assigned_kanban

      # New lane
      assert_select '#new-requests' do
        assert_select "#incoming-issues-user-#{@user.id}-project-0.incoming-issues" do
          assert_select "li#issue_#{@new_issue1.id}", :count => 1
          assert_select "li#issue_#{@new_issue2.id}", :count => 1
          assert_select "li#issue_#{@new_watched_issue.id}", :count => 0
        end
      end
      assert_select "li#issue_#{@different_assigned_to_new_issue.id}", :count => 0
      
      # Testing lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
            assert_select "li#issue_#{@testing_issue1.id}", :count => 1
            assert_select "li#issue_#{@testing_issue2.id}", :count => 1
            assert_select "li#issue_#{@testing_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_testing_issue.id}", :count => 0
      
      # Active lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
            assert_select "li#issue_#{@active_issue1.id}", :count => 1
            assert_select "li#issue_#{@active_issue2.id}", :count => 1
            assert_select "li#issue_#{@active_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_active_issue.id}", :count => 0

      # Don't show an issue assigned to a non-member (e.g. issue assigned and then moved)
      assert_select "#active-issues-user-#{@user.id}-project-#{@another_project.id}.active-issues", :count => 0 do
        assert_select "li#issue_#{@non_member_issue.id}", :count => 0
      end

      # Selected lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
            assert_select "li#issue_#{@selected_issue1.id}", :count => 1
            assert_select "li#issue_#{@selected_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_selected_issue.id}", :count => 0

      # Backlog lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
            assert_select "li#issue_#{@backlog_issue1.id}", :count => 1
            assert_select "li#issue_#{@backlog_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_backlog_issue1.id}", :count => 0

      # Finished lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#finished-issues-user-#{@user.id}-project-#{@project.id}.finished-issues" do
            assert_select "li#issue_#{@finished_issue.id}", :count => 1
            assert_select "li#issue_#{@finished_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_finished_issue.id}", :count => 0

      # Canceled lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#canceled-issues-user-#{@user.id}-project-#{@project.id}.canceled-issues" do
            assert_select "li#issue_#{@canceled_issue.id}", :count => 1
            assert_select "li#issue_#{@canceled_watched_issue.id}", :count => 0
          end
        end
      end
      assert_select "li#issue_#{@different_assigned_to_canceled_issue.id}", :count => 0
    end

    should "show the upcoming deadlines" do
      # Due Today
      @today = Issue.generate_for_project!(@project, :due_date => Date.today)
      @past_due = Issue.generate_for_project!(@project, :due_date => 3.days.ago)

      # Due in 3 days
      @in_3_days = Issue.generate_for_project!(@project, :due_date => 3.days.from_now + 1.hour)
      @in_4_days = Issue.generate_for_project!(@project, :due_date => 4.days.from_now + 1.hour)

      # Due in 7 days
      @in_7_days = Issue.generate_for_project!(@project, :due_date => 7.days.from_now + 1.hour)
      @in_8_days = Issue.generate_for_project!(@project, :due_date => 8.days.from_now + 1.hour)

      # Due in 14 days
      @in_14_days = Issue.generate_for_project!(@project, :due_date => 14.days.from_now + 1.hour)
      @in_15_days = Issue.generate_for_project!(@project, :due_date => 15.days.from_now + 1.hour)

      # Due in 30 days
      @in_30_days = Issue.generate_for_project!(@project, :due_date => 30.days.from_now + 1.hour)
      @in_31_days = Issue.generate_for_project!(@project, :due_date => 31.days.from_now + 1.hour)

      @in_70_days = Issue.generate_for_project!(@project, :due_date => 70.days.from_now + 1.hour)
      
      login_as
      visit_assigned_kanban

      assert_select "#deadlines" do
        assert_select ".due-today" do
          assert_select "li#issue_#{@today.id}", :count => 1
          assert_select "li#issue_#{@past_due.id}", :count => 1
        end

        assert_select ".due-in-3-days" do
          assert_select "li#issue_#{@in_3_days.id}", :count => 1
          assert_select "li#issue_#{@in_4_days.id}", :count => 1
        end

        assert_select ".due-in-7-days" do
          assert_select "li#issue_#{@in_7_days.id}", :count => 1
          assert_select "li#issue_#{@in_8_days.id}", :count => 1
        end

        assert_select ".due-in-14-days" do
          assert_select "li#issue_#{@in_14_days.id}", :count => 1
          assert_select "li#issue_#{@in_15_days.id}", :count => 1
        end

        assert_select ".due-in-30-days" do
          assert_select "li#issue_#{@in_30_days.id}", :count => 1
          assert_select "li#issue_#{@in_31_days.id}", :count => 1
        end

        assert_select "li#issue_#{@in_70_days.id}", :count => 0
      end

    end
    
  end
end
