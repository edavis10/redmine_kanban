class KanbanPane::BacklogPane < KanbanPane
  def get_issues(options={})
    return {} if missing_settings('backlog')

    for_option = options.delete(:for)
    user = options.delete(:user)
    user_id = user ? user.id : nil
    exclude_ids = options.delete(:exclude_ids)

    conditions = ''
    conditions << " #{Issue.table_name}.status_id IN (:status)"
    conditions << " AND #{Issue.table_name}.id NOT IN (:excluded_ids)" unless exclude_ids.empty?

    if user.present?
      for_conditions = []
      if for_option.include?(:author)
        for_conditions << " #{Issue.table_name}.author_id = :user"
      end

      if for_option.include?(:watcher)
        for_conditions << " #{Watcher.table_name}.user_id = :user"
      end

      if for_conditions.present?
        conditions << " AND ("
        conditions << for_conditions.join(" OR ")
        conditions << " ) "
      end
    end
    
    issues = Issue.visible.all(:limit => settings['panes']['backlog']['limit'],
                               :order => "#{RedmineKanban::KanbanCompatibility::IssuePriority.klass.table_name}.position ASC, #{Issue.table_name}.created_on ASC",
                               :include => [:priority, :watchers],
                               :conditions => [conditions, {
                                                 :status => settings['panes']['backlog']['status'],
                                                 :excluded_ids => exclude_ids,
                                                 :user => user_id
                                               }])
                                                 

    return group_by_priority_position(issues)
  end
  
end

