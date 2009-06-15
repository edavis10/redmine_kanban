require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  context "on GET to :show" do
    setup {
      configure_plugin
      # Private Project
      private_project = make_project_with_trackers(:is_public => false)
      5.times do
        Issue.make(:tracker => private_project.trackers.first,
                   :project => private_project,
                   :status => IssueStatus.find_by_name('Active'))

      end

      public_project = make_project_with_trackers(:is_public => true)
      6.times do
        Issue.make(:tracker => public_project.trackers.first,
                   :project => public_project,
                   :status => IssueStatus.find_by_name('New'))
      end

      high_priority = IssuePriority.make(:name => "High")
      5.times do
        Issue.make(:tracker => public_project.trackers.first,
                   :project => public_project,
                   :priority => high_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      medium_priority = IssuePriority.make(:name => "Medium")
      7.times do
        Issue.make(:tracker => public_project.trackers.first,
                   :project => public_project,
                   :priority => medium_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      low_priority = IssuePriority.make(:name => "Low")
      5.times do
        Issue.make(:tracker => public_project.trackers.first,
                   :project => public_project,
                   :priority => low_priority,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end

      @user = User.make
      @request.session[:user_id] = @user.id
      get :show
    }

    should_assign_to :settings
    should_assign_to :incoming_issues
    should_assign_to :backlog_issues

    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash

    should "only get incoming issues up to the limit" do
      assert_equal 5, assigns(:incoming_issues).size
    end

    should "only get incoming issues with the configured status" do
      assigns(:incoming_issues).each do |issue|
        assert_equal 'New', issue.status.name
      end
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
end
