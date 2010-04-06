class Kanban
  attr_accessor :incoming_issues
  attr_accessor :quick_issues
  attr_accessor :backlog_issues
  attr_accessor :selected_issues
  attr_accessor :active_issues
  attr_accessor :testing_issues
  attr_accessor :finished_issues
  attr_accessor :canceled_issues
  attr_accessor :settings
  attr_accessor :users

  def self.non_kanban_issues_panes
     ["incoming","backlog", "quick","finished","canceled"]
  end

  def self.kanban_issues_panes
    ['selected','active','testing']
  end

  def self.valid_panes
    kanban_issues_panes + non_kanban_issues_panes
  end

  def self.staffed_panes
    ['active','testing','finished','canceled']
  end

  def self.find
    kanban = Kanban.new
    kanban.settings = Setting.plugin_redmine_kanban
    kanban.users = kanban.get_users
    kanban.incoming_issues = kanban.get_incoming_issues
    kanban.quick_issues = kanban.get_quick_issues
    kanban.backlog_issues = kanban.get_backlog_issues(kanban.quick_issues.to_a.flatten.collect(&:id))
    kanban.selected_issues = KanbanIssue.find_selected
    kanban.active_issues = kanban.get_active
    kanban.testing_issues = kanban.get_testing
    kanban.finished_issues = kanban.get_finished_issues
    kanban.canceled_issues = kanban.get_canceled_issues
    kanban
  end

  def get_incoming_issues
    get_issues_for_pane(:incoming)
  end

  def get_backlog_issues(exclude_ids=[])
    get_issues_for_pane(:backlog, :exclude_ids => exclude_ids)
  end

  def get_quick_issues
    get_issues_for_pane(:quick)
  end

  def get_finished_issues
    get_issues_for_pane(:finished)
  end

  def get_canceled_issues
    get_issues_for_pane(:canceled)
  end

  def get_users
    role = Role.find_by_id(@settings["staff_role"])
    @users = role.members.collect(&:user).uniq.compact.sort if role
    @users ||= []
    @users = move_current_user_to_front
    @users << UnknownUser.instance
    @users
  end

  def get_active
    issues_from_kanban_issue(:active)
  end

  def get_testing
    issues_from_kanban_issue(:testing)
  end
  
  def quick_issue_ids
    return @quick_issues.collect {|ary| ary[1] }.flatten.collect(&:id)
  end

  # Updates the Issue with +issue_id+ to change it's
  # * Status to the IssueStatus set for the +to+ pane
  # * Assignment to the +target_user+ on staffed panes
  def self.update_issue_attributes(issue_id, from, to, user=User.current, target_user=nil)
    @settings = Setting.plugin_redmine_kanban

    issue = Issue.find_by_id(issue_id)

    if @settings['panes'][to] && @settings['panes'][to]['status']
      new_status = IssueStatus.find_by_id(@settings['panes'][to]['status'])
    end
      
    if issue && new_status
      issue.init_journal(user)
      issue.status = new_status

      if Kanban.staffed_panes.include?(to) && !target_user.nil? && target_user.is_a?(User)
        issue.assigned_to = target_user
      end

      return issue.save
    else
      return false
    end

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

  private

  def move_current_user_to_front
    if user = @users.delete(User.current)
      @users.unshift(user)
    else
      @users
    end
  end

  def missing_settings(pane, options={})
    skip_status = options.delete(:skip_status)

    @settings.blank? ||
      @settings['panes'].blank? ||
      @settings['panes'][pane].blank? ||
      @settings['panes'][pane]['limit'].blank? ||
      (@settings['panes'][pane]['status'].blank? && !skip_status)
  end

  # Sort and group a set of issues based on IssuePriority#position
  def group_by_priority_position(issues)
    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position
    }
  end

  def get_issues_for_pane(pane, options = {})
    case pane
    when :finished
      KanbanPane::FinishedPane.new.get_issues(options)
    when :canceled
      KanbanPane::CanceledPane.new.get_issues(options)
    when :quick
      KanbanPane::QuickPane.new.get_issues(options)
    when :backlog
      KanbanPane::BacklogPane.new.get_issues(options)
    when :incoming
      KanbanPane::IncomingPane.new.get_issues(options)
    else
      return [[]]
    end
    
  end

  def issues_from_kanban_issue(pane)
    return {} unless [:active, :testing].include?(pane)
    
    issues = {}
    @users.each do |user|
      issues[user] = KanbanIssue.send('find_' + pane.to_s, user.id)
    end unless @users.blank?
    issues

  end
end
