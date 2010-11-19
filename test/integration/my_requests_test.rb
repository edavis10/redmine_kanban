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
      click_link "My Requests"
      
      assert_response :success
      assert_equal "/kanban/my-requests", current_url

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

    context "Incoming title" do
      should "be linked to the configured url when the url is present" do
        login_as
        visit_my_kanban_requests

        assert_select "h3 a[href=?]", Setting.plugin_redmine_kanban['panes']['incoming']['url'], :text => "Incoming"
      end

      should "not be linked if the url isn't present" do
        panes = Setting.plugin_redmine_kanban['panes']
        panes['incoming']['url'] = ''
        reconfigure_plugin({'panes' => panes})
        
        login_as
        visit_my_kanban_requests

        assert_select "h3 a", :text => "Incoming", :count => 0
        assert_select "h3", :text => "Incoming"
      end
    end

    should "show the user help content using the text formatting" do
        login_as
        visit_my_kanban_requests

      assert_select '.user-help' do
        assert_select 'strong', :text => 'This is user help'
      end
    end

    should "not allow showing another user's User Kanban page" do
      login_as
      visit_my_kanban_requests

      assert_select "form#user_switch", :count => 0

      # Visit by url hacking
      visit "/kanban/users/#{@another_user.id}"
      assert_response :forbidden
      assert_template 'common/error'

    end

    
    should "show the swimlanes" do
      @new_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @new_status)
      @new_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @new_status)
      @different_author_new_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @new_status)

      @testing_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @testing_status)
      @testing_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @testing_status)
      @different_author_testing_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @testing_status)
      @active_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @active_status)
      @active_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @active_status)
      @different_author_active_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @active_status)
      @selected_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @selected_status)
      @different_author_selected_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @selected_status)
      @backlog_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @unstaffed_status, :estimated_hours => 5)
      @different_author_backlog_issue1 = Issue.generate_for_project!(@project, :author => @another_user, :status => @unstaffed_status, :estimated_hours => 5)

      @finished_issue = Issue.generate_for_project!(@project, :author => @user, :status => @finished_status)
      @different_author_finished_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @finished_status)
      @canceled_issue = Issue.generate_for_project!(@project, :author => @user, :status => @canceled_status)
      @different_author_canceled_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @canceled_status)
      
      # Not a member but created
      @another_project = Project.generate!
      @non_member_issue = Issue.generate_for_project!(@another_project, :author => @user, :status => @active_status)

      # Watched issues
      @new_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @new_status)
      @testing_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @testing_status)
      @active_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @active_status)
      @selected_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @selected_status)
      @backlog_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @unstaffed_status, :estimated_hours => 5)
      @finished_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @finished_status)
      @canceled_watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @canceled_status)

      [@new_watched_issue, @testing_watched_issue, @active_watched_issue, @selected_watched_issue, @backlog_watched_issue, @finished_watched_issue, @canceled_watched_issue].each do |issue|
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => issue.id, :user => @user)
        assert issue.watched_by? @user
      end

      login_as
      visit_my_kanban_requests

      # New lane
      assert_select '#new-requests' do
        assert_select "#incoming-issues-user-#{@user.id}-project-0.incoming-issues" do
          assert_select "li#issue_#{@new_issue1.id}", :count => 1
          assert_select "li#issue_#{@new_issue2.id}", :count => 1
          assert_select "li#issue_#{@new_watched_issue.id}", :count => 1
        end
      end
      assert_select "li#issue_#{@different_author_new_issue.id}", :count => 0
      
      # Testing lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
            assert_select "li#issue_#{@testing_issue1.id}", :count => 1
            assert_select "li#issue_#{@testing_issue2.id}", :count => 1
            assert_select "li#issue_#{@testing_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_testing_issue.id}", :count => 0
      
      # Active lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
            assert_select "li#issue_#{@active_issue1.id}", :count => 1
            assert_select "li#issue_#{@active_issue2.id}", :count => 1
            assert_select "li#issue_#{@active_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_active_issue.id}", :count => 0

      # Show an issue on a project that the current user isn't a member of but the current user created the issue (e.g. issue created and then moved)
      assert_select "#active-issues-user-#{@user.id}-project-#{@another_project.id}.active-issues" do
        assert_select "li#issue_#{@non_member_issue.id}", :count => 1
      end
      
      # Selected lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
            assert_select "li#issue_#{@selected_issue1.id}", :count => 1
            assert_select "li#issue_#{@selected_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_selected_issue.id}", :count => 0

      # Backlog lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
            assert_select "li#issue_#{@backlog_issue1.id}", :count => 1
            assert_select "li#issue_#{@backlog_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_backlog_issue1.id}", :count => 0

      # Finished lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#finished-issues-user-#{@user.id}-project-#{@project.id}.finished-issues" do
            assert_select "li#issue_#{@finished_issue.id}", :count => 1
            assert_select "li#issue_#{@finished_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_finished_issue.id}", :count => 0

      # Canceled lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#canceled-issues-user-#{@user.id}-project-#{@project.id}.canceled-issues" do
            assert_select "li#issue_#{@canceled_issue.id}", :count => 1
            assert_select "li#issue_#{@canceled_watched_issue.id}", :count => 1
          end
        end
      end
      assert_select "li#issue_#{@different_author_canceled_issue.id}", :count => 0
    end

    should "group issues under the parent project with a project_level of 1" do
      configure_plugin({'project_level' => '1'})
      
      @subproject = Project.generate!
      assert @subproject.set_parent!(@project)
      assert_equal @project, @subproject.parent
      @project.reload
      @subproject.reload
      Member.generate!({:principal => @user, :project => @subproject, :roles => [@role]})
      
      @new_issue1 = Issue.generate_for_project!(@subproject, :author => @user, :status => @new_status)
      @testing_issue1 = Issue.generate_for_project!(@subproject, :author => @user, :status => @testing_status)
      @active_issue1 = Issue.generate_for_project!(@subproject, :author => @user, :status => @active_status)
      @selected_issue1 = Issue.generate_for_project!(@subproject, :author => @user, :status => @selected_status)
      @backlog_issue1 = Issue.generate_for_project!(@subproject, :author => @user, :status => @unstaffed_status, :estimated_hours => 5)
      @finished_issue = Issue.generate_for_project!(@subproject, :author => @user, :status => @finished_status)
      @canceled_issue = Issue.generate_for_project!(@subproject, :author => @user, :status => @canceled_status)

      login_as
      visit_my_kanban_requests

      # Show parent project
      assert_select '#kanban' do
        assert_select '.project-lane h2.project-name', :text => /#{@project.name}/
      end
      
      # Don't show subproject below limit
      assert_select '#kanban' do
        assert_select '.project-lane h2.project-name', :text => /#{@subproject.name}/, :count => 0
      end
          
      # New lane
      assert_select '#new-requests' do
        assert_select "#incoming-issues-user-#{@user.id}-project-0.incoming-issues" do
          assert_select "li#issue_#{@new_issue1.id}", :count => 1
        end
      end

      # Testing lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
            assert_select "li#issue_#{@testing_issue1.id}", :count => 1
          end
        end
      end
      
      # Active lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
            assert_select "li#issue_#{@active_issue1.id}", :count => 1
          end
        end
      end

      # Selected lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
            assert_select "li#issue_#{@selected_issue1.id}", :count => 1
          end
        end
      end

      # Backlog lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
            assert_select "li#issue_#{@backlog_issue1.id}", :count => 1
          end
        end
      end

      # Finished lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#finished-issues-user-#{@user.id}-project-#{@project.id}.finished-issues" do
            assert_select "li#issue_#{@finished_issue.id}", :count => 1
          end
        end
      end

      # Canceled lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#canceled-issues-user-#{@user.id}-project-#{@project.id}.canceled-issues" do
            assert_select "li#issue_#{@canceled_issue.id}", :count => 1
          end
        end
      end

    end
    
    should "group each horizontal lane by project" do
      login_as
      Issue.generate_for_project!(@project, :author => @user, :status => @active_status)
      visit_my_kanban_requests

      assert_select '#kanban' do
        assert_select 'div.project-lane' do
          assert_select '.project-name', :text => /#{@public_project.reload.name}/, :count => 0 # No issues
          assert_select '.project-name', :text => /#{@project.reload.name}/
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

      assert_select "#content", :text => /#{@another_user.to_s}'s Requests/
    end
    
      
  end
end
