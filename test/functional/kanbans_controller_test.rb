require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  context "on GET to :show" do
    setup { get :show }

    should_respond_with :success
    should_render_template :show
    should_not_set_the_flash
  end
end
