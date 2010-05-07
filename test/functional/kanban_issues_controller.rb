require File.dirname(__FILE__) + '/../test_helper'

class KanbanIssuesControllerTest < ActionController::TestCase
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
      should ":edit_kanban to view edit" do
        get :edit, :format => 'js'
        assert_response :success
      end
    end

    context "deny access should use" do
      setup {
        @user.members.destroy_all
      }

      should ":edit_kanban" do
        get :edit, :format => 'js'
        assert_response 406 # TODO: Redmine's not supporting js in render_403
      end
    end

  end

  context "GET #edit with HTML" do
    setup do
      shared_setup
    end
    
    should "not be allowed" do
      get :edit
      assert_response 406
    end
  end

  context "GET #edit with JS" do
    setup do
      shared_setup
    end

    context "without an issue id" do
      should "return a 404"
    end

    context "with an issue id the current user cannot see" do
      should "return a 404"
    end

    context "with an issue id the current user can see" do
      context "without coming from incoming" do
        should "return a 404"
      end

      context "coming from the incoming pane" do
        should "return a 200"
        should "render the issue form"
      end
    end

  end
end
