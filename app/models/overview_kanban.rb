class OverviewKanban < Kanban
  def initialize(attributes={})
    super
    @for = [:assigned_to]
    @fill_incoming = false
    @fill_backlog = false
  end

  def get_users
    u = super
    u.reject {|user| user.is_a?(UnknownUser) }
  end

  # After filtering issues, extract the highest priority one
  def filter_issues(issues, filters = {})
    filtered_issues = super(issues, filters)
    return filtered_issues unless filtered_issues.present?

    [extract_highest_priority_issue(filtered_issues)] # expects an Array returned
  end

  # After filtering issues, extract the highest priority one
  def backlog_issues_for(options={})
    issues = super
    [extract_highest_priority_issue(issues)] # expects an Array returned
  end

  # Returns the first issue sorted by highest priority.
  # Optionally if subissues_take_higher_priority is configured, then the
  # highest priority subissue will be returned
  def extract_highest_priority_issue(issues)
    # Sort subissues higher?
    if Setting.plugin_redmine_kanban['panels'].present? &&
        Setting.plugin_redmine_kanban['panels']['overview'].present? &&
        Setting.plugin_redmine_kanban['panels']['overview']['subissues_take_higher_priority'].to_s == "1"
      subissues = issues.select {|issue| issue.parent_issue_id.present? }

      if subissues.present?
        return subissues.sort {|a,b| a.priority.position <=> b.priority.position}.first
      end
    end
    return issues.sort {|a,b| a.priority.position <=> b.priority.position}.first
  end
end
