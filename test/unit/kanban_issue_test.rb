require File.dirname(__FILE__) + '/../test_helper'

class KanbanIssueTest < ActiveSupport::TestCase
  def shared_setup
    @project = make_project_with_trackers
    @issue = Issue.generate!(:project => @project, :tracker => @project.trackers.first)
    @user = User.generate_with_protected!
    @role = make_kanban_role
    
    @member = make_member({
                            :user => @user,
                            :project => @project
                          },
                          [@role])
    @kanban_issue = KanbanIssue.new(:issue => @issue, :user => @user, :state => "none", :position => 1)
  end

  should_validate_presence_of :position

  should_belong_to :issue
  should_belong_to :user

  context 'state' do
    should 'use aasm' do
      assert KanbanIssue.included_modules.include?(AASM)
    end

    should 'have a none state' do
      assert KanbanIssue.aasm_states.collect(&:name).include?(:none)
    end

    should 'have a selected state' do
      assert KanbanIssue.aasm_states.collect(&:name).include?(:selected)
    end

    should 'have an active state' do
      assert KanbanIssue.aasm_states.collect(&:name).include?(:active)
    end

    should 'have a testing state' do
      assert KanbanIssue.aasm_states.collect(&:name).include?(:testing)
    end

  end

  context 'selected!' do
    setup do
      shared_setup
      @object = @kanban_issue
    end
    
    should_allow_state_change_from 'none', :to => 'selected', :using => 'selected!'
    should_allow_state_change_from 'active', :to => 'selected', :using => 'selected!'
    should_allow_state_change_from 'testing', :to => 'selected', :using => 'selected!'
  end

  context 'active!' do
    setup do
      shared_setup
      @object = @kanban_issue
    end
    
    should_allow_state_change_from 'none', :to => 'active', :using => 'active!'
    should_allow_state_change_from 'selected', :to => 'active', :using => 'active!'
    should_allow_state_change_from 'testing', :to => 'active', :using => 'active!'
  end
  
  context 'testing!' do
    setup do
      shared_setup
      @object = @kanban_issue
    end
    
    should_allow_state_change_from 'none', :to => 'testing', :using => 'testing!'
    should_allow_state_change_from 'selected', :to => 'testing', :using => 'testing!'
    should_allow_state_change_from 'active', :to => 'testing', :using => 'testing!'
  end
  
  context 'associations to user' do
    setup do
      shared_setup
      @kanban_issue.save!
    end
    
    should 'be empty in the Selected state' do
      @kanban_issue.user = @user
      @kanban_issue.selected!
      assert_nil @kanban_issue.user
    end

    should 'not be empty in the Active state' do
      @kanban_issue.active!
      assert_equal @user, @kanban_issue.user
    end

    should 'not be empty in the Testing state' do
      @kanban_issue.testing!
      assert_equal @user, @kanban_issue.user
    end
  end

  context 'position' do
    should 'use acts_as_list' do
      shared_setup
      assert @kanban_issue.acts_as_list_class, "Missing acts_as_list defination"
    end

    should 'be scoped based on the State and User' do
      shared_setup
      assert_equal "state = 'none' AND user_id = #{@kanban_issue.user_id}", @kanban_issue.scope_condition
    end
  end

  context 'update_from_issue' do
    setup {
      setup_kanban_issues
      setup_selected_issues
    }
    
    context 'to a status without a kanban issue setting' do
      should 'remove all KanbanIssues for the issue' do
        
        setup_kanban_issues
        unconfigured_status = IssueStatus.generate!(:name => 'NoKanban')
        kanban = KanbanIssue.last
        assert kanban
        assert kanban.issue
        issue = kanban.issue

        assert issue
        issue.status = unconfigured_status
        assert issue.save
        KanbanIssue.update_from_issue(issue)
        assert_nil KanbanIssue.find_by_id(kanban.id)
      end
    end

    context 'to a status with a kanban status' do
      should 'create a new KanbanIssue if there is not one already' do
        assert_difference('KanbanIssue.count') do
          @issue = Issue.generate!(:tracker => @public_project.trackers.first,
                              :project => @public_project,
                              :status => IssueStatus.find_by_name('Selected'))
        end
        
        kanban_issue = KanbanIssue.find(:last)
        assert_equal @issue, kanban_issue.issue
        assert_equal 'selected', kanban_issue.state
      end

      should 'change the state of an existing KanbanIssue' do
        kanban_issue = KanbanIssue.find_by_state('selected')
        assert_equal 'selected', kanban_issue.state

        issue = kanban_issue.issue
        issue.status = IssueStatus.find_by_name('Active')
        issue.save
        kanban_issue.reload

        assert_equal 'active', kanban_issue.state
      end

      should 'assign the KanbanIssue to the assigned to user if the state is active or testing' do
        kanban_issue = KanbanIssue.find_by_state('selected')
        assert_equal 'selected', kanban_issue.state

        issue = kanban_issue.issue
        issue.assigned_to = User.generate_with_protected!
        issue.status = IssueStatus.find_by_name('Active')
        issue.save
        kanban_issue.reload

        assert_equal issue.assigned_to, kanban_issue.user
      end
    end

    should 'return true' do
      @public_project = make_project_with_trackers(:is_public => true)
      issue = Issue.generate!(:tracker => @public_project.trackers.first,
                         :project => @public_project)

      assert KanbanIssue.update_from_issue(issue)
    end
  end
end
