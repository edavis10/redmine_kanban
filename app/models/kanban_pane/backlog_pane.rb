class KanbanPane::BacklogPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('backlog')

    exclude_ids = options.delete(:exclude_ids)

    conditions = ARCondition.new
    conditions.add ["#{Issue.table_name}.status_id IN (?)", settings['panes']['backlog']['status']]
    conditions.add ["#{Issue.table_name}.id NOT IN (?)", exclude_ids] unless exclude_ids.empty?

    issues = Issue.visible.all(:limit => settings['panes']['backlog']['limit'],
                               :order => "#{RedmineKanban::KanbanCompatibility::IssuePriority.klass.table_name}.position ASC, #{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => conditions.conditions)

    return group_by_priority_position(issues)
  end
  
end

