class Kanban
  attr_accessor :incoming_issues
  attr_accessor :quick_issues
  attr_accessor :backlog_issues
  attr_accessor :selected_issues
  attr_accessor :active_issues
  attr_accessor :testing_issues
  attr_accessor :settings
  attr_accessor :users

  def self.non_kanban_issues_panes
     ["incoming","backlog", "quick"]
  end

  def self.kanban_issues_panes
    ['selected','active','testing']
  end

  def self.valid_panes
    kanban_issues_panes + non_kanban_issues_panes
  end
  
  def self.find
    kanban = Kanban.new
    kanban.settings = Setting.plugin_redmine_kanban
    kanban.users = kanban.get_users
    kanban.incoming_issues = kanban.get_incoming_issues
    kanban.quick_issues = kanban.get_quick_issues
    kanban.backlog_issues = kanban.get_backlog_issues(kanban.quick_issues.values.flatten.collect(&:id))
    kanban.selected_issues = KanbanIssue.find_selected
    kanban.active_issues = kanban.get_active
    kanban.testing_issues = kanban.get_testing
    kanban
  end

  def get_incoming_issues
    return Issue.visible.find(:all,
                              :limit => @settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => {:status_id => @settings['panes']['incoming']['status']})
  end

  def get_backlog_issues(exclude_ids=[])
    issues = Issue.visible.all(:limit => @settings['panes']['backlog']['limit'],
                               :order => "#{IssuePriority.table_name}.position ASC, #{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => ["#{Issue.table_name}.status_id IN (?) AND #{Issue.table_name}.id NOT IN (?)", @settings['panes']['backlog']['status'], exclude_ids])

    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position # Sorted based on IssuePriority#position
    }
  end

  # TODO: similar to backlog issues
  def get_quick_issues
    issues = Issue.visible.all(:limit => @settings['panes']['quick-tasks']['limit'],
                               :order => "#{IssuePriority.table_name}.position ASC, #{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => {:status_id => @settings['panes']['backlog']['status'], :estimated_hours => nil})

    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position # Sorted based on IssuePriority#position
    }
  end

  def get_users
    role = Role.find_by_id(@settings["staff_role"])
    @users = role.members.collect(&:user).uniq.sort if role
  end

  def get_active
    active = {}
    @users.each do |user|
      active[user] = KanbanIssue.find_active(user.id)
    end
    active
  end

  def get_testing
    testing = {}
    @users.each do |user|
      testing[user] = KanbanIssue.find_testing(user.id)
    end
    testing
  end
  
  def quick_issue_ids
    return @quick_issues.values.flatten.collect(&:id)
  end

  # Updates +target_pane+ so that the KanbanIssues match +sorted_issues+
  def self.update_sorted_issues(target_pane, sorted_issues, user_id=nil)
    if Kanban.kanban_issues_panes.include?(target_pane)
      if sorted_issues.blank? && !target_pane.blank?
        KanbanIssue.destroy_all(:state => target_pane, :user_id => user_id)
      else
        # Remove items that are in the database but not in the
        # sorted_issues
        if user_id
          KanbanIssue.destroy_all(['state = ? AND user_id = ? AND issue_id NOT IN (?)',target_pane, user_id, sorted_issues])
        else
          KanbanIssue.destroy_all(['state = ? AND issue_id NOT IN (?)',target_pane, sorted_issues])
        end
          
        sorted_issues.each_with_index do |issue_id, zero_position|
          kanban_issue = KanbanIssue.find_by_issue_id(issue_id)
          if kanban_issue
            if kanban_issue.state != target_pane
              # Change state
              kanban_issue.send(target_pane.to_sym)
            end
            kanban_issue.user_id = user_id unless target_pane == 'selected'
            kanban_issue.position = zero_position + 1 # acts_as_list is 1 based
            kanban_issue.save
          else
            kanban_issue = KanbanIssue.new
            kanban_issue.issue_id = issue_id
            kanban_issue.state = target_pane
            kanban_issue.user_id = user_id unless target_pane == 'selected'
            kanban_issue.position = (zero_position + 1)
            kanban_issue.save
            # Need to resave since acts_as_list automatically moves a
            # new issue to the bottom on create
            kanban_issue.insert_at(zero_position + 1)
          end
        end
      end
    end
  end
end
