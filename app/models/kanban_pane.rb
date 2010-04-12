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
end
