require File.dirname(__FILE__) + '/../test_helper'

class KanbansControllerTest < ActionController::TestCase
  context "on GET to :index" do
    setup { get :index }

    should_respond_with :success
    should_render_template :index
    should_not_set_the_flash
  end
end
