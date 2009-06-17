require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  def shared_setup
    configure_plugin
    @private_project = make_project_with_trackers(:is_public => false)
    @public_project = make_project_with_trackers(:is_public => true)
    @user = User.make
    @request.session[:user_id] = @user.id
  end
  
  context "on GET to :show" do
    setup {
      shared_setup
      get :show
    }

    should_assign_to :settings
    should_assign_to :incoming_issues
    should_assign_to :backlog_issues

    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash
  end
  
  context "on GET to :show for incoming issues" do
    setup do
      shared_setup
      5.times do
        Issue.make(:tracker => @private_project.trackers.first,
                   :project => @private_project,
                   :status => IssueStatus.find_by_name('New'))
      end

      6.times do
        Issue.make(:tracker => @public_project.trackers.first,
                   :project => @public_project,
                   :status => IssueStatus.find_by_name('New'))
      end

      get :show
    end
      
    should "only get incoming issues up to the limit" do
      assert_equal 5, assigns(:incoming_issues).size
    end

    should "only get incoming issues with the configured status" do
      assigns(:incoming_issues).each do |issue|
        assert_equal 'New', issue.status.name
      end
    end
  end

  context "on GET to :show for backlog issues" do
    setup do
      shared_setup
      high_priority = IssuePriority.make(:name => "High")
      5.times do
        Issue.make(:tracker => @public_project.trackers.first,
                   :project => @public_project,
                   :priority => high_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      medium_priority = IssuePriority.make(:name => "Medium")
      7.times do
        Issue.make(:tracker => @public_project.trackers.first,
                   :project => @public_project,
                   :priority => medium_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      low_priority = IssuePriority.make(:name => "Low")
      5.times do
        Issue.make(:tracker => @public_project.trackers.first,
                   :project => @public_project,
                   :priority => low_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      get :show
    end
    
    should "only get backlog issues up to the limit" do
      assert_equal 3, assigns(:backlog_issues).size # Priorities
      assert_equal 15, assigns(:backlog_issues).values.collect.flatten.size # Issues
    end

    should "only get backlog issues with the configured status" do
      assigns(:backlog_issues).each do |priority, issues|
        issues.each do |issue|
          assert_equal 'Unstaffed', issue.status.name
        end
      end
    end

    should "group backlog issues by IssuePriority" do
      assert_equal IssuePriority.find_by_name("High"),  assigns(:backlog_issues).keys[0]
      assert_equal IssuePriority.find_by_name("Medium"),  assigns(:backlog_issues).keys[1]
      assert_equal IssuePriority.find_by_name("Low"),  assigns(:backlog_issues).keys[2]
    end

    should "render nested lists for the grouping" do
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
      should_assign_to :incoming_issues
      should_assign_to :backlog_issues
      
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

