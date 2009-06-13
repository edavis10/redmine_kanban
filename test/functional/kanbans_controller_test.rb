require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  context "on GET to :show" do
    setup {
      configure_plugin
      # Active issues
      10.times do
        Issue.make(:tracker => @incoming_project.trackers.first,
                   :project => @incoming_project,
                   :status => IssueStatus.find_by_name('Active'))

      end

      6.times do
        Issue.make(:tracker => @incoming_project.trackers.first,
                   :project => @incoming_project,
                   :status => IssueStatus.find_by_name('Unstaffed'))
      end
      
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
        assert_equal 'Unstaffed', issue.status.name
      end
    end
  end

  context "on GET to :show with no incoming project" do
    setup {
      configure_plugin({'incoming_project' => ''})
      get :show
    }

    should_not_assign_to :incoming_issues

    should "not show the Incoming pane if the Incoming project isn't setup" do
      assert_select("div#incoming", :count => 0)
    end
  end
end
