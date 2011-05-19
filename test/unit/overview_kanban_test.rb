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
    configure_plugin
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

    context "with subissues_take_higher_priority set to true" do
      setup do
        Setting.plugin_redmine_kanban['panels']['overview']['subissues_take_higher_priority'] = '1'
      end

      should "pick the highest priority of subissues" do
        @medium = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @high = Issue.generate_for_project!(@project, :priority => high_priority).reload
        @medium2 = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @medium_subissue = Issue.generate_for_project!(@project, :priority => medium_priority, :parent_issue_id => @medium.id).reload
        @high_subissue = Issue.generate_for_project!(@project, :priority => high_priority, :parent_issue_id => @medium.id).reload

        assert_equal @high_subissue, @kanban.extract_highest_priority_issue([@medium, @high, @medium2, @medium_subissue, @high_subissue])

      end
      
      should "consider a subissue a higher priority than normal issues" do
        @medium = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @high = Issue.generate_for_project!(@project, :priority => high_priority).reload
        @medium2 = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @medium_subissue = Issue.generate_for_project!(@project, :priority => medium_priority, :parent_issue_id => @medium.id).reload

        assert_equal @medium_subissue, @kanban.extract_highest_priority_issue([@medium, @high, @medium2, @medium_subissue])
      end
      
    end

    context "with subissues_take_higher_priority set to false" do
      setup do
        Setting.plugin_redmine_kanban['panels']['overview']['subissues_take_higher_priority'] = '0'
      end
      
      should "pick the highest priority issue, disregarding subissue status" do
        @medium = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @high = Issue.generate_for_project!(@project, :priority => high_priority).reload
        @medium2 = Issue.generate_for_project!(@project, :priority => medium_priority).reload
        @medium_subissue = Issue.generate_for_project!(@project, :priority => medium_priority, :parent_issue_id => @medium.id).reload

        assert_equal @high, @kanban.extract_highest_priority_issue([@medium, @high, @medium2, @medium_subissue])

      end
      
    end
    
  end
end
