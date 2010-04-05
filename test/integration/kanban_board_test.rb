require 'test_helper'

class KanbanBoardTest < ActionController::IntegrationTest
  setup do
    configure_plugin
    setup_kanban_issues
    setup_all_issues

    @public_project = make_project_with_trackers(:is_public => true)
    @user = User.generate_with_protected!(:login => 'user', :password => 'password', :password_confirmation => 'password')
    @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :edit_kanban])
    @member = make_member({:principal => @user, :project => @public_project}, [@role])
  end

  context "viewing the board" do
    should "show a bubble icon on issues where the last journal was not made by the assigned user" do

      active_status = IssueStatus.find_by_name('Active')
      issue_with_note = Issue.find(:first, :conditions => {:status_id => active_status.id})
      issue_with_note_by_assigned = Issue.find(:last, :conditions => {:status_id => active_status.id})
      assert issue_with_note != issue_with_note_by_assigned

      Journal.generate!(:journalized => issue_with_note, :notes => 'an update that triggers the bubble')
      Journal.generate!(:journalized => issue_with_note_by_assigned, :user => issue_with_note_by_assigned.assigned_to, :notes => 'an update by assigned to')
      # Another journal but with no notes, should not trigger the bubble
      Journal.generate!(:journalized => issue_with_note_by_assigned, :notes => '')

      log_user('user', 'password')
      get "/kanban"
      
      assert_response :success

      assert_select "#issue_#{issue_with_note_by_assigned.id}"
      assert_select "#issue_#{issue_with_note_by_assigned.id} .updated-note", :count => 0
      assert_select "#issue_#{issue_with_note.id}"
      assert_select "#issue_#{issue_with_note.id} .updated-note", :count => 1
    end
  end

end
