class KanbanPane
  def settings
    Setting.plugin_redmine_kanban
  end

  def get_issues(options={})
    nil
  end

  private

  # TODO: Wrapper until moved from Kanban
  def missing_settings(pane, options={})
    kanban = Kanban.new
    kanban.settings = Setting.plugin_redmine_kanban
    kanban.send(:missing_settings, pane, options)
  end
end
