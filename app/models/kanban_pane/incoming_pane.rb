class KanbanPane::IncomingPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('incoming')
    
    conditions = ARCondition.new
    conditions.add ["status_id = ?", settings['panes']['incoming']['status']]

    return Issue.visible.find(:all,
                              :limit => settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => conditions.conditions)

  end
  
end

