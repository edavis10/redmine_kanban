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

      @user = User.make
      @request.session[:user_id] = @user.id
      get :show
    }

    should_assign_to :settings
    should_assign_to :incoming_issues

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
  end
end
