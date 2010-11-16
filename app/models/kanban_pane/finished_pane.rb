class KanbanPane::FinishedPane < KanbanPane
  def get_issues(options={})
    return {} if missing_settings('finished')
    for_option = options.delete(:for)
    user = options.delete(:user)
    user_id = user ? user.id : nil

    status_id = settings['panes']['finished']['status']
    days = settings['panes']['finished']['limit'] || 7

    conditions = ''
    conditions << " #{Issue.table_name}.status_id = :status"
    conditions << " AND #{Issue.table_name}.updated_on > :days"

    if user.present?
      for_conditions = []
      if for_option.include?(:author)
        for_conditions << " #{Issue.table_name}.author_id = :user"
      end

      if for_option.include?(:watcher)
        for_conditions << " #{Watcher.table_name}.user_id = :user"
      end

      if for_option.include?(:assigned_to)
        for_conditions << "#{Issue.table_name}.assigned_to_id = :user"
      end

      if for_conditions.present?
        conditions << " AND ("
        conditions << for_conditions.join(" OR ")
        conditions << " ) "
      end
    end
    
    issues = Issue.visible.all(:include => [:assigned_to, :watchers],
                               :order => "#{Issue.table_name}.updated_on DESC",
                               :conditions => [conditions, {
                                                 :status => status_id,
                                                 :days => days.to_f.days.ago,
                                                 :user => user_id
                                               }])

    return issues.group_by(&:assigned_to)
  end
  
end

