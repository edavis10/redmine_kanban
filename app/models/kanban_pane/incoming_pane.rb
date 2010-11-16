class KanbanPane::IncomingPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('incoming')
    for_option = options.delete(:for)
    user = options.delete(:user)
    user_id = user ? user.id : nil

    conditions = ''
    conditions << "status_id = :status"
    conditions = merge_for_option_conditions(conditions, for_option) if user.present?
    
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

