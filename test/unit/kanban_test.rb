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

    context "for selected issues" do
      should "only get selected issues up to the limit" do
        assert_equal 8, @kanban.selected_issues.length
      end

      should "only get selected issues with the configured status" do
        @kanban.selected_issues.each do |kanban_issue|
          assert_equal 'Selected', kanban_issue.issue.status.name
        end
      end
    end

    context "for active issues" do
      
      should "only get active issues up to the limit" do
        assert_equal 3, @kanban.active_issues.size # Users
        assert_equal 15, @kanban.active_issues.values.collect.flatten.size # Issues
      end

      should "only get issues with the configured Active status" do
        @kanban.active_issues.each do |user, kanban_issues|
          kanban_issues.each do |kanban_issue|
            assert_equal 'Active', kanban_issue.issue.status.name
          end
        end
      end

      should "group active issues by User" do
        @kanban.active_issues.keys.each do |key|
          assert key.is_a?(User)
        end
      end
    end

    context "for testing issues" do
      
      should "only get testing issues up to the limit" do
        assert_equal 3, @kanban.testing_issues.size # Users
        assert_equal 15, @kanban.testing_issues.values.collect.flatten.size # Issues
      end

      should "only get issues with the configured Testing status" do
        @kanban.testing_issues.each do |user, kanban_issues|
          kanban_issues.each do |kanban_issue|
            assert_equal 'Test-N-Doc', kanban_issue.issue.status.name
          end
        end
      end

      should "group testing issues by User" do
        @kanban.testing_issues.keys.each do |key|
          assert key.is_a?(User)
        end
      end
    end

    should "set @users based on the configured role" do
      assert_equal 3, @kanban.users.length
    end
  end

  context "#update_sorted_issues" do
    setup {
      shared_setup
      setup_kanban_issues
    }

    context "with 0 issues" do
      should 'remove all KanbanIssues for that pane' do
        assert_difference('KanbanIssue.count', -10) do
          Kanban.update_sorted_issues('selected',[])
        end
      end
    end

    context "with a new KanbanIssue" do
      should "create a new KanbanIssue" do
        KanbanIssue.destroy_all
        issue = Issue.make({
                             :tracker => @public_project.trackers.first,
                             :project => @public_project
                           })
        
        assert_difference('KanbanIssue.count') do
          Kanban.update_sorted_issues('selected',[issue.id])
        end

        kanban_issue = KanbanIssue.find_by_issue_id(issue.id)
        assert kanban_issue
        assert_equal 1, kanban_issue.position
        assert_equal 'selected', kanban_issue.state
      end
    end

    context "with an existing KanbanIssue" do
      setup {
        @issue = Issue.make({
                             :tracker => @public_project.trackers.first,
                             :project => @public_project
                           })
        @kanban_issue = KanbanIssue.make({
                                           :issue => @issue,
                                           :user => nil,
                                           :state => 'none',
                                           :position => 3
                                         })
      }
      
      should "change the state to the pane's state" do
        Kanban.update_sorted_issues('selected',[@issue.id])
        @kanban_issue.reload
        assert_equal "selected", @kanban_issue.state
      end

      should "update the position based on the sorted_issues" do
        Kanban.update_sorted_issues('selected',[@issue.id])
        @kanban_issue.reload
        assert_equal 1, @kanban_issue.position
      end
    end
  end
end

