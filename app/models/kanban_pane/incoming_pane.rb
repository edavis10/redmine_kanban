class KanbanPane::IncomingPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('incoming')
    for_option = options.delete(:for)
    user = options.delete(:user)
    user_id = user ? user.id : nil

    conditions = ''
    conditions << "status_id = :status"

    if user.present?
      for_conditions = []
      if for_option.include?(:author)
        for_conditions << "#{Issue.table_name}.author_id = :user"
      end

      if for_option.include?(:watcher)
        for_conditions << "#{Watcher.table_name}.user_id = :user"
      end

      if for_conditions.present?
        conditions << " AND ("
        conditions << for_conditions.join(" OR ")
        conditions << " ) "
      end
    end
    
    return Issue.visible.
      all(:limit => settings['panes']['incoming']['limit'],
          :order => "#{Issue.table_name}.created_on ASC",
          :include => :watchers,
          :conditions => [conditions, {
                            :status => settings['panes']['incoming']['status'],
                            :user => user_id
                          }])
  end

end

