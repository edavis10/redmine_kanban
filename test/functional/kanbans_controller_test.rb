require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  context "on GET to :show" do
    setup {
      configure_plugin
      get :show
    }

    should_assign_to :settings
    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash
  end

  context "on GET to :show with no incoming project" do
    setup {
      configure_plugin({'incoming_project' => ''})
      get :show
    }

    should "not show the Incoming pane if the Incoming project isn't setup" do
      assert_select("div#incoming", :count => 0)
    end
  end
end
