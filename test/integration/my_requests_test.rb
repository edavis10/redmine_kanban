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

    context "load the swimlanes using ajax" do
      setup do
        login_as
      end

      should "load the new requests lane" do
        @new_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @new_status)
        @new_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @new_status)
        @different_author_new_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @new_status)

        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @new_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/users/#{@user.id}.js?column=incoming"
        doc = HTML::Document.new(response.body)

        assert_select doc.root, "#incoming-issues-user-#{@user.id}-project-0.incoming-issues" do
          assert_select "li#issue_#{@new_issue1.id}", :count => 1
          assert_select "li#issue_#{@new_issue2.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_new_issue.id}", :count => 0
      end
      
      should "load the testing lane" do
        @testing_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @testing_status)
        @testing_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @testing_status)
        @different_author_testing_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @testing_status)
        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @testing_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/users/#{@user.id}.js?column=testing&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        assert_select doc.root, "#testing-issues-user-#{@user.id}-project-#{@project.id}.testing-issues" do
          assert_select "li#issue_#{@testing_issue1.id}", :count => 1
          assert_select "li#issue_#{@testing_issue2.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_testing_issue.id}", :count => 0
      end
      
      should "load the active lane" do
        @active_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @active_status)
        @active_issue2 = Issue.generate_for_project!(@project, :author => @user, :status => @active_status)
        @different_author_active_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @active_status)

        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @active_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/users/#{@user.id}.js?column=active&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        assert_select doc.root, "#active-issues-user-#{@user.id}-project-#{@project.id}.active-issues" do
          assert_select "li#issue_#{@active_issue1.id}", :count => 1
          assert_select "li#issue_#{@active_issue2.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_active_issue.id}", :count => 0
      end
      
      should "load the selected lane" do
        @selected_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @selected_status)
        @different_author_selected_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @selected_status)

        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @selected_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/users/#{@user.id}.js?column=selected&project=#{@project.id}"
        doc = HTML::Document.new(response.body)
        
        assert_select doc.root, "#selected-issues-user-#{@user.id}-project-#{@project.id}.selected-issues" do
          assert_select "li#issue_#{@selected_issue1.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_selected_issue.id}", :count => 0
      end

      should "load the backlog lane" do
        @backlog_issue1 = Issue.generate_for_project!(@project, :author => @user, :status => @unstaffed_status, :estimated_hours => 5)
        @different_author_backlog_issue1 = Issue.generate_for_project!(@project, :author => @another_user, :status => @unstaffed_status, :estimated_hours => 5)

        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @unstaffed_status, :estimated_hours => 5)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        visit "/kanban/users/#{@user.id}.js?column=backlog&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        assert_select doc.root, "#backlog-issues-user-#{@user.id}-project-#{@project.id}.backlog-issues" do
          assert_select "li#issue_#{@backlog_issue1.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_backlog_issue1.id}", :count => 0
      end

      should "load the finished lane" do
        @finished_issue = Issue.generate_for_project!(@project, :author => @user, :status => @finished_status)
        @different_author_finished_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @finished_status)

        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @finished_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user
        
        visit "/kanban/users/#{@user.id}.js?column=finished&project=#{@project.id}"
        doc = HTML::Document.new(response.body)

        assert_select doc.root, "#finished-issues-user-#{@user.id}-project-#{@project.id}.finished-issues" do
          assert_select "li#issue_#{@finished_issue.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_finished_issue.id}", :count => 0
      end

      should "load the canceled lane" do
        @canceled_issue = Issue.generate_for_project!(@project, :author => @user, :status => @canceled_status)
        @different_author_canceled_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @canceled_status)
        @watched_issue = Issue.generate_for_project!(@project, :author => @another_user, :status => @canceled_status)
        Watcher.generate!(:watchable_type => "Issue", :watchable_id => @watched_issue.id, :user => @user)
        assert @watched_issue.watched_by? @user

        
        visit "/kanban/users/#{@user.id}.js?column=canceled&project=#{@project.id}"
        doc = HTML::Document.new(response.body)
        
        assert_select doc.root, "#canceled-issues-user-#{@user.id}-project-#{@project.id}.canceled-issues" do
          assert_select "li#issue_#{@canceled_issue.id}", :count => 1
          assert_select "li#issue_#{@watched_issue.id}", :count => 1
        end
        assert_select "li#issue_#{@different_author_canceled_issue.id}", :count => 0
      end
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
        assert_select "#user-kanban-show-incoming" do
            assert_select 'span.loading'
        end
      end

      # Testing lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#user-kanban-show-testing-project-#{@project.id}" do
            assert_select 'span.loading'
          end
        end
      end
      
      # Active lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#user-kanban-show-active-project-#{@project.id}" do
            assert_select 'span.loading'
          end
        end
      end

      # Selected lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#user-kanban-show-selected-project-#{@project.id}" do
            assert_select 'span.loading'
          end
        end
      end

      # Backlog lane
      assert_select '#kanban' do
        assert_select '.project-lane' do
          assert_select "#user-kanban-show-backlog-project-#{@project.id}" do
            assert_select 'span.loading'
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

    should_show_deadlines(:created) { visit_my_kanban_requests }
    should_allow_overriding_the_incoming_pane_link_when_linked_to_a_project { visit_my_kanban_requests }

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
