require File.dirname(__FILE__) + '/../test_helper'

class KanbanIssueTest < Test::Unit::TestCase
  def setup
    @project = make_project_with_trackers
    @issue = Issue.make(:project => @project, :tracker => @project.trackers.first)
    @user = User.make
    @role = Role.make
    @member = make_member({
                            :user => @user,
                            :project => @project
                          },
                          [@role])
    @kanban_issue = KanbanIssue.new(:issue => @issue, :user => @user)
  end

  should_validate_presence_of :position
  should_validate_presence_of :state

  should_belong_to :issue
  should_belong_to :user
  
  
  should 'use state to store which phase of Kanban it it currently in'
  should 'have an association to an Issue'
  context 'associations to user' do

    should 'be empty in the Selected state'
    should 'not be empty in the Active state'
    should 'not be empty in the Testing state'
  end

  context 'position' do
    should 'use acts_as_list'
    should 'be scoped based on the State and User'
  end
end
