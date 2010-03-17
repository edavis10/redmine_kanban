require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  def shared_setup
    configure_plugin
    @private_project = make_project_with_trackers(:is_public => false)
    @public_project = make_project_with_trackers(:is_public => true)
    @user = User.generate_with_protected!
    @request.session[:user_id] = @user.id
    @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :edit_kanban])
    @member = make_member({:principal => @user, :project => @public_project}, [@role])
  end

  context "permissions" do
    setup {
      shared_setup
    }

    context "allow" do
      should ":view_kanban to view show" do
        get :show
        assert_response :success
      end

      should ":edit_kanban to put update" do
        put :update, {}
        assert_response :redirect
      end
    end

    context "deny access should use" do
      setup {
        @user.members.destroy_all
      }

      should ":view_kanban" do
        get :show
        assert_response 403
      end

      should ":edit_kanban" do
        put :update, {}
        assert_response 403
      end
    end

  end

  context "on GET to :show" do
    setup {
      shared_setup
      setup_kanban_issues
      setup_all_issues

      # Bloody hack since @public_project is redefined....
      @member = make_member({:principal => @user, :project => @public_project}, [@role])
      assert @user.allowed_to?(:view_kanban, @public_project)

      get :show
    }

    should_assign_to :settings
    should_assign_to :kanban

    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash
  
    should "render nested lists for the backlog" do
      assert_select("ol#backlog-issues") do
        assert_select("ol.high") do
          assert_select("li", :count => 5)
        end
        assert_select("ol.medium") do
          assert_select("li", :count => 7)
        end
        assert_select("ol.low") do
          assert_select("li", :count => 3)
        end
      end
    end


    should "render nested lists for the quick issues" do
      assert_select("ol#quick-issues") do
        assert_select("ol.high") do
          assert_select("li", :count => 4)
        end
        assert_select("ol.medium") do
          assert_select("li", :count => 1)
        end
      end
    end
  end  

  context "on PUT to :update for HTML format" do
    setup {
      shared_setup
    }

    context "with no data" do
      setup {
        put :update, {}
      }

      should_respond_with :redirect
      should_redirect_to("main page") { kanban_path }
      should_set_the_flash_to /error/i
    end

    context "from Incoming to Backlog for an issue" do
      setup {
        shared_setup
        @from = "incoming"
        @to = "backlog"
        high_priority = IssuePriority.find_by_name("High")
        high_priority ||= IssuePriority.generate!(:name => "High", :type => 'IssuePriority') if high_priority.nil?
        @issue = Issue.generate!(:tracker => @public_project.trackers.first,
                            :project => @public_project,
                            :priority => high_priority,
                            :status => IssueStatus.find_by_name('New'))

        put :update, {:from => @from, :to => @to, :issue_id => @issue.id}
      }

      should_redirect_to("main page") { kanban_path }
      should_set_the_flash_to /updated/i

      should "update the issue status to 'to'" do
        @issue.reload
        assert_equal "Unstaffed", @issue.status.name
      end

    end
    
  end
  
  context "on PUT to :update for JSON format" do
    setup {
      shared_setup
    }

    context "with no data" do
      should "return an empty object" do
        xhr :put, :update
        assert_equal '{}', @response.body
      end

      should "respond with error" do
        xhr :put, :update
        assert_response :bad_request
      end
    end

    context "from Incoming to Backlog for an issue #" do
      setup {
        shared_setup
        @from = "incoming"
        @to = "backlog"
        high_priority = IssuePriority.find_by_name("High")
        high_priority ||= IssuePriority.generate!(:name => "High", :type => 'IssuePriority') if high_priority.nil?
        @issue = Issue.generate!(:tracker => @public_project.trackers.first,
                            :project => @public_project,
                            :priority => high_priority,
                            :status => IssueStatus.find_by_name('New'))

        xhr :put, :update, {:from => @from, :to => @to, :issue_id => @issue.id}
      }
      
      should_respond_with :success
      should_assign_to :settings
      should_assign_to :kanban

      should "update the issue status to 'to'" do
        @issue.reload
        assert_equal "Unstaffed", @issue.status.name
      end

      should "return the updated Incoming panes content" do
        json = ActiveSupport::JSON.decode @response.body
        assert json.keys.include?('from')
      end

      should "return the updated Backlog panes content" do
        json = ActiveSupport::JSON.decode @response.body
        assert json.keys.include?('to')
      end
    end
    
  end

  context "on PUT to :sync" do
    setup do
      shared_setup
      setup_kanban_issues
      setup_all_issues
    end

    context "" do
      setup do
        put :sync
      end
      
      should_respond_with :redirect
      should_set_the_flash_to /sync/i
      should_redirect_to("main page") { kanban_path }
    end

    should "update outdated selected records" do
      selected_status = IssueStatus.find_by_name('Selected')
      unstaffed_status = IssueStatus.find_by_name('Unstaffed')
      issue_moved_from_selected = Issue.first(:conditions => {:status_id => selected_status.id})
      issue_moved_from_selected.update_attributes(:status_id => IssueStatus.find_by_name('Active').id,
                                                  :assigned_to => @user)

      issue_moved_into_selected = Issue.first(:conditions => {:status_id => unstaffed_status.id})
      issue_moved_into_selected.update_attributes(:status_id => selected_status.id)

      assert KanbanIssue.find_by_issue_id(issue_moved_from_selected.id).destroy
      assert KanbanIssue.find_by_issue_id(issue_moved_into_selected.id).destroy

      put :sync

      issue_moved_from_selected.reload
      assert_equal IssueStatus.find_by_name('Active'), issue_moved_from_selected.status
      kanban_issue_moved_from = KanbanIssue.find_by_issue_id(issue_moved_from_selected.id)
      assert_equal 'active', kanban_issue_moved_from.state
      assert_equal @user, kanban_issue_moved_from.user
      assert_equal 1, kanban_issue_moved_from.position # First for user

      issue_moved_into_selected.reload
      assert_equal IssueStatus.find_by_name('Selected'), issue_moved_into_selected.status
      kanban_issue_moved_into = KanbanIssue.find_by_issue_id(issue_moved_into_selected.id)
      assert_equal 'selected', kanban_issue_moved_into.state
      assert_equal 11, kanban_issue_moved_into.position
    end

    should "update outdated active records xxx" do
      selected_status = IssueStatus.find_by_name('Selected')
      unstaffed_status = IssueStatus.find_by_name('Unstaffed')
      active_status = IssueStatus.find_by_name('Active')
      issue_moved_from_active = Issue.first(:conditions => {:status_id => active_status.id})
      issue_moved_from_active.update_attributes(:status_id => selected_status.id)

      issue_moved_into_active = Issue.first(:conditions => {:status_id => unstaffed_status.id})
      issue_moved_into_active.update_attributes(:status_id => active_status.id, :assigned_to => @user)

      assert KanbanIssue.find_by_issue_id(issue_moved_from_active.id).destroy
      assert KanbanIssue.find_by_issue_id(issue_moved_into_active.id).destroy

      put :sync

      issue_moved_from_active.reload
      assert_equal selected_status, issue_moved_from_active.status
      kanban_issue_moved_from = KanbanIssue.find_by_issue_id(issue_moved_from_active.id)
      assert_equal 'selected', kanban_issue_moved_from.state
      assert_equal nil, kanban_issue_moved_from.user
      assert_equal 11, kanban_issue_moved_from.position

      issue_moved_into_active.reload
      assert_equal active_status, issue_moved_into_active.status
      kanban_issue_moved_into = KanbanIssue.find_by_issue_id(issue_moved_into_active.id)
      assert_equal 'active', kanban_issue_moved_into.state
      assert_equal @user, kanban_issue_moved_into.user
      assert_equal 1, kanban_issue_moved_into.position # First for user

    end
    
    should "update outdated testing records xxx" do
      selected_status = IssueStatus.find_by_name('Selected')
      unstaffed_status = IssueStatus.find_by_name('Unstaffed')
      active_status = IssueStatus.find_by_name('Active')
      testing_status = IssueStatus.find_by_name('Test-N-Doc')

      issue_moved_from_testing = Issue.first(:conditions => {:status_id => testing_status.id})
      issue_moved_from_testing.update_attributes(:status_id => selected_status.id)

      issue_moved_into_testing = Issue.first(:conditions => {:status_id => unstaffed_status.id})
      issue_moved_into_testing.update_attributes(:status_id => testing_status.id, :assigned_to => @user)

      assert KanbanIssue.find_by_issue_id(issue_moved_from_testing.id).destroy
      assert KanbanIssue.find_by_issue_id(issue_moved_into_testing.id).destroy

      put :sync

      issue_moved_from_testing.reload
      assert_equal selected_status, issue_moved_from_testing.status
      kanban_issue_moved_from = KanbanIssue.find_by_issue_id(issue_moved_from_testing.id)
      assert_equal 'selected', kanban_issue_moved_from.state
      assert_equal nil, kanban_issue_moved_from.user
      assert_equal 11, kanban_issue_moved_from.position

      issue_moved_into_testing.reload
      assert_equal testing_status, issue_moved_into_testing.status
      kanban_issue_moved_into = KanbanIssue.find_by_issue_id(issue_moved_into_testing.id)
      assert_equal 'testing', kanban_issue_moved_into.state
      assert_equal @user, kanban_issue_moved_into.user
      assert_equal 1, kanban_issue_moved_into.position # First for user

    end
  end
end

