class KanbanPane::IncomingPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('incoming')
    for_option = options.delete(:for)
    user = options.delete(:user)

    conditions = ARCondition.new
    conditions.add ["status_id = ?", settings['panes']['incoming']['status']]
    conditions.add ["#{Issue.table_name}.author_id = ?", user] if for_option == :author && user.present?

    return Issue.visible.find(:all,
                              :limit => settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => conditions.conditions)

  end
  
end

