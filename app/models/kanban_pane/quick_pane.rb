class KanbanPane::QuickPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('quick-tasks', :skip_status => true) || missing_settings('backlog')

    conditions = ARCondition.new

    conditions.add ["status_id = ?", settings['panes']['backlog']['status']]
    conditions.add "estimated_hours IS null"

    issues = Issue.visible.all(:limit => settings['panes']['quick-tasks']['limit'],
                               :order => "#{RedmineKanban::KanbanCompatibility::IssuePriority.klass.table_name}.position ASC, #{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => conditions.conditions)

    # TODO: Remove wrapper
    kanban = Kanban.new
    return kanban.send(:group_by_priority_position, issues)
  end
  
end

