class KanbanPane
  def settings
    Setting.plugin_redmine_kanban
  end

  def get_issues(options={})
    nil
  end

  private

  def missing_settings(pane, options={})
    skip_status = options.delete(:skip_status)

    settings.blank? ||
      settings['panes'].blank? ||
      settings['panes'][pane].blank? ||
      settings['panes'][pane]['limit'].blank? ||
      (settings['panes'][pane]['status'].blank? && !skip_status)
  end

  # Sort and group a set of issues based on IssuePriority#position
  def group_by_priority_position(issues)
    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position
    }
  end

end
