require File.dirname(__FILE__) + '/../test_helper'

class OverviewKanbanTest < ActiveSupport::TestCase
  def setup
    @user = User.generate!
    User.current = @user
    @project = Project.generate!
    @kanban = OverviewKanban.new
    high_priority
    medium_priority
    low_priority
  end

  context "#extract_highest_priority_issue" do
    should "return nil with no issues" do
      assert_equal nil, @kanban.extract_highest_priority_issue([])
    end
    
    should "return the issue with the highest priority (by position)" do
      @medium = Issue.generate_for_project!(@project, :priority => medium_priority).reload
      @high = Issue.generate_for_project!(@project, :priority => high_priority).reload
      @medium2 = Issue.generate_for_project!(@project, :priority => medium_priority).reload
      assert_equal @high, @kanban.extract_highest_priority_issue([@medium, @high, @medium2])
    end
    
  end
end
