require File.dirname(__FILE__) + '/../test_helper'

class KanbanTest < Test::Unit::TestCase
  def shared_setup
    configure_plugin
    @user = User.make
    User.current = @user
  end

  context "#find" do
    setup {
      shared_setup
      setup_kanban_issues

      @kanban = Kanban.find
    }

    context "for incoming issues" do
      should "only get incoming issues up to the limit" do
        assert_equal 5, @kanban.incoming_issues.size
      end

      should "only get incoming issues with the configured status" do
        @kanban.incoming_issues.each do |issue|
          assert_equal 'New', issue.status.name
        end
      end
    end
    
    context "for backlog issues" do
      should "only get backlog issues up to the limit" do
        assert_equal 3, @kanban.backlog_issues.size # Priorities
        assert_equal 15, @kanban.backlog_issues.values.collect.flatten.size # Issues
      end

      should "only get backlog issues with the configured status" do
        @kanban.backlog_issues.each do |priority, issues|
          issues.each do |issue|
            assert_equal 'Unstaffed', issue.status.name
          end
        end
      end

      should "not include issues that are already in the Quick Issues list" do
        @kanban.backlog_issues.each do |priority, issues|
          issues.each do |issue|
            assert !@kanban.quick_issue_ids.include?(issue.id)
          end
        end
      end

      should "group backlog issues by IssuePriority" do
        assert_equal IssuePriority.find_by_name("High"),  @kanban.backlog_issues.keys[0]
        assert_equal IssuePriority.find_by_name("Medium"),  @kanban.backlog_issues.keys[1]
        assert_equal IssuePriority.find_by_name("Low"),  @kanban.backlog_issues.keys[2]
      end
    end

    context "for quick issues" do
      
      should "only get quick issues up to the limit" do
        assert_equal 2, @kanban.quick_issues.size # Priorities
        assert_equal 5, @kanban.quick_issues.values.collect.flatten.size # Issues
      end

      should "only get quick issues with the configured Backlog status" do
        @kanban.quick_issues.each do |priority, issues|
          issues.each do |issue|
            assert_equal 'Unstaffed', issue.status.name
          end
        end
      end

      should "group quick issues by IssuePriority" do
        assert_equal IssuePriority.find_by_name("High"),  @kanban.quick_issues.keys[0]
        assert_equal IssuePriority.find_by_name("Medium"),  @kanban.quick_issues.keys[1]
      end
    end
  end      
end

