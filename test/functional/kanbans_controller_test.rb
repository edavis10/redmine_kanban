require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  def shared_setup
    configure_plugin
    @private_project = make_project_with_trackers(:is_public => false)
    @public_project = make_project_with_trackers(:is_public => true)
    @user = User.make
    @request.session[:user_id] = @user.id
    @role = Role.make
    @member = make_member({:user => @user, :project => @public_project}, @role)
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
        high_priority ||= IssuePriority.make(:name => "High") if high_priority.nil?
        @issue = Issue.make(:tracker => @public_project.trackers.first,
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
        high_priority ||= IssuePriority.make(:name => "High") if high_priority.nil?
        @issue = Issue.make(:tracker => @public_project.trackers.first,
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

end

