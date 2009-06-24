require File.dirname(__FILE__) + '/../test_helper'

class KanbanIssueTest < Test::Unit::TestCase
  def shared_setup
    @project = make_project_with_trackers
    @issue = Issue.make(:project => @project, :tracker => @project.trackers.first)
    @user = User.make
    @role = Role.make
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
    should 'be empty in the Selected state'
    should 'not be empty in the Active state'
    should 'not be empty in the Testing state'
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
end
