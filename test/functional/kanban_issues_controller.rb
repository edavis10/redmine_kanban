require File.dirname(__FILE__) + '/../test_helper'

class KanbanIssuesControllerTest < ActionController::TestCase
  def shared_setup
    setup_kanban_issues
    configure_plugin
    @private_project = make_project_with_trackers(:is_public => false)
    @public_project = make_project_with_trackers(:is_public => true)
    @user = User.generate_with_protected!(:admin => true)
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
        issue = Issue.generate_for_project!(@public_project)
        get :edit, :from_pane => 'incoming', :id => issue.id, :format => 'js'
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
      assert_response 404
    end
  end

  context "GET #edit with JS" do
    setup do
      shared_setup
    end

    context "without an issue id" do
      should "return a 404" do
        get :edit, :format => 'js'
        assert_response 404
      end
    end

    context "with an issue id the current user cannot see" do
      should "return a 404" do
        private_issue = Issue.generate_for_project!(@private_project)
        get :edit, :id => private_issue.id, :format => 'js'
        assert_response 404
      end
    end

    context "with an issue id the current user can see" do
      setup do
        @issue = Issue.generate_for_project!(@public_project)
      end

      context "without coming from incoming" do
        should "return a 404" do
          get :edit, :id => @issue.id, :format => 'js'
          assert_response 404
        end
      end

      context "coming from the incoming pane" do
        should "return a 200" do
          get :edit, :id => @issue.id, :from_pane => 'incoming', :format => 'js'
          assert_response 200
        end

        should "render the issue form for incoming" do
          get :edit, :id => @issue.id, :from_pane => 'incoming', :format => 'js'
          assert_template 'kanban_issues/edit_incoming'
        end

        should "assign issue priorities to exclude the configuration setting" do
          get :edit, :id => @issue.id, :from_pane => 'incoming', :format => 'js'

          assert assigns(:priorities)
          assert_contains assigns(:priorities), @high_priority
          assert_contains assigns(:priorities), @medium_priority
          assert_contains assigns(:priorities), @low_priority
          assert !assigns(:priorities).include?(@priority_hidden_from_incoming), "Excluded priority is displayed when it should not be"
        end

        should "assign allowed_projects to exclude the configuration setting" do
          get :edit, :id => @issue.id, :from_pane => 'incoming', :format => 'js'

          assert assigns(:allowed_projects)
          assert !assigns(:allowed_projects).include?(@hidden_project), "Excluded project is displayed when it should not be"
        end
      end
    end

  end
end
