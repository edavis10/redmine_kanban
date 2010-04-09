require File.dirname(__FILE__) + '/../test_helper'

class KanbanTest < ActiveSupport::TestCase
  def shared_setup

    @user = User.generate_with_protected!
    User.current = @user
  end

  context "#find" do
    setup {
      shared_setup
      configure_plugin
      setup_kanban_issues
      make_member({:principal => @user, :project => @public_project}, [Role.last])
    }

    context "for incoming issues" do
      setup {
        setup_incoming_issues
        @kanban = Kanban.new
      }

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
      setup {
        setup_backlog_issues
        @kanban = Kanban.new
      }

      should "only get backlog issues up to the limit" do
        assert_equal 3, @kanban.backlog_issues.size # Priorities
        assert_equal 15, @kanban.backlog_issues.collect {|a| a[1]}.flatten.size # Issues
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
        assert_equal IssuePriority.find_by_name("High"),  @kanban.backlog_issues.first.first
        assert_equal IssuePriority.find_by_name("Medium"),  @kanban.backlog_issues[1].first
        assert_equal IssuePriority.find_by_name("Low"),  @kanban.backlog_issues[2].first
      end
    end

    context "for quick issues" do
      setup {
        setup_quick_issues
        @kanban = Kanban.new
      }
      
      should "only get quick issues up to the limit" do
        assert_equal 2, @kanban.quick_issues.size # Priorities
        assert_equal 5, @kanban.quick_issues.collect {|a| a[1]}.flatten.size # Issues
      end

      should "only get quick issues with the configured Backlog status" do
        @kanban.quick_issues.each do |priority, issues|
          issues.each do |issue|
            assert_equal 'Unstaffed', issue.status.name
          end
        end
      end

      should "group quick issues by IssuePriority" do
        assert_equal IssuePriority.find_by_name("High"),  @kanban.quick_issues.first.first
        assert_equal IssuePriority.find_by_name("Medium"),  @kanban.quick_issues[1].first
      end
    end

    context "for selected issues" do
      setup {
        setup_selected_issues
        @kanban = Kanban.new
      }

      should "get all selected issues" do
        assert_equal 10, @kanban.selected_issues.length
      end

      should "only get selected issues with the configured status" do
        @kanban.selected_issues.each do |kanban_issue|
          assert_equal 'Selected', kanban_issue.issue.status.name
        end
      end
    end

    context "for active issues" do
      setup {
        setup_active_issues
        setup_unknown_user_issues
        @kanban = Kanban.new
      }
      
      should "only get all active issues" do
        assert_equal 5, @kanban.active_issues.size # Users + Unknown
        assert_equal 18, @kanban.active_issues.values.collect.flatten.size # Issues
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
          assert key.is_a?(UnknownUser) || key.is_a?(User)
        end
      end
    end

    context "for testing issues" do
      setup {
        setup_testing_issues
        setup_unknown_user_issues
        @kanban = Kanban.new
      }
      
      should "only get all testing issues" do
        assert_equal 5, @kanban.testing_issues.size # Users + Unknow
        assert_equal 19, @kanban.testing_issues.values.collect.flatten.size # Issues
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
          assert key.is_a?(UnknownUser) || key.is_a?(User)
        end
      end
    end

    context "for finished issues" do
      setup {
        setup_finished_issues
        @kanban = Kanban.new
      }

      should "only get issues with the configured Finished status" do
        @kanban.finished_issues.each do |user, issues|
          issues.each do |issue|
            assert_equal 'Closed', issue.status.name
          end
        end
      end

      should "only get issues from the last 7 days" do
        @kanban.finished_issues.each do |user, issues|
          issues.each do |issue|
            assert issue.updated_on > 7.days.ago
          end
        end
      end
    
      should "group issues by User" do
        @kanban.finished_issues.keys.each do |key|
          assert key.is_a?(UnknownUser) || key.is_a?(User)
        end
      end
    end

    context "for canceled issues" do
      setup {
        setup_canceled_issues
        @kanban = Kanban.new
      }

      should "only get issues with the configured Canceled status" do
        @kanban.canceled_issues.each do |user, issues|
          issues.each do |issue|
            assert_equal 'Rejected', issue.status.name
          end
        end
      end

      should "only get issues from the last 7 days" do
        @kanban.canceled_issues.each do |user, issues|
          issues.each do |issue|
            assert issue.updated_on > 7.days.ago
          end
        end
      end
    
      should "group issues by User" do
        @kanban.canceled_issues.keys.each do |key|
          assert key.is_a?(UnknownUser) || key.is_a?(User)
        end
      end
    end

    should "set @users based on the configured role" do
      @kanban = Kanban.new
      assert_equal 5, @kanban.users.length # +1 Unknown
    end
  end

  context "#update_sorted_issues" do
    setup {
      shared_setup
      setup_kanban_issues
    }

    context "with 0 issues" do
      should 'remove all KanbanIssues for that pane' do
        total = KanbanIssue.count(:conditions => {:state => 'selected'}) * -1
        assert_difference('KanbanIssue.count', total) do
          Kanban.update_sorted_issues('selected',[])
        end
      end
    end

    context "with a new KanbanIssue" do
      should "create a new KanbanIssue" do
        KanbanIssue.destroy_all
        issue = Issue.generate!({
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
        @issue = Issue.generate!({
                             :tracker => @public_project.trackers.first,
                             :project => @public_project
                           })
        @kanban_issue = KanbanIssue.generate!({
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

  context "#update_issue_attributes" do
    setup {
      shared_setup
      setup_kanban_issues
      @from = "incoming"
      @to = "active"
      @high_priority = IssuePriority.find_by_name("High")
      @high_priority ||= IssuePriority.generate!(:name => "High", :type => 'IssuePriority') if @high_priority.nil?

      @issue = Issue.generate!(:tracker => @public_project.trackers.first,
                          :project => @public_project,
                          :priority => @high_priority,
                          :status => IssueStatus.find_by_name('New'))
    }

    should "update the issue status to the 'to' pane's Status" do
      Kanban.update_issue_attributes(@issue, @from, @to, @user)
      @issue.reload
      assert_equal "Active", @issue.status.name
    end

    should "return true if the issue was saved" do
      assert Kanban.update_issue_attributes(@issue, @from, @to, @user)
    end

    should "return false if the issue wasn't found" do
      assert !Kanban.update_issue_attributes('1234567890', @from, @to, @user)
    end

    should "return false if the issue didn't save"

    context "to a staffed pane" do
      should "assign the issue to the target user if the target user is set" do
        Kanban.update_issue_attributes(@issue, @from, @to, @user, @user)
        @issue.reload
        assert_equal @user, @issue.assigned_to
      end

      should "keep the user assignment if the target user is nil" do
        @issue.update_attribute(:assigned_to, @user)
        @issue.reload

        Kanban.update_issue_attributes(@issue, @from, @to, @user, nil)
        @issue.reload
        assert_equal @user, @issue.assigned_to
      end

    end

    context "to an unstaffed pane" do
      setup {
        @to = 'backlog'
        @from = 'active'
        @issue.update_attribute(:assigned_to, @user)
        @issue.reload
      }

      should "keep the user assignement if the target user is set" do
        Kanban.update_issue_attributes(@issue, @from, @to, @user, @user)
        @issue.reload
        assert_equal @user, @issue.assigned_to
      end

      should "keep the user assignement if the target user is nil" do
        Kanban.update_issue_attributes(@issue, @from, @to, @user, nil)
        @issue.reload
        assert_equal @user, @issue.assigned_to
      end

    end
  end

end
