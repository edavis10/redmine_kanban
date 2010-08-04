class KanbanPane::CanceledPane < KanbanPane
  def get_issues(options={})
    return [[]] if missing_settings('canceled')
    for_option = options.delete(:for)
    user = options.delete(:user)

    status_id = settings['panes']['canceled']['status']
    days = settings['panes']['canceled']['limit'] || 7

    conditions = ARCondition.new
    conditions.add ["#{Issue.table_name}.status_id = ?", status_id]
    conditions.add ["#{Issue.table_name}.updated_on > ?", days.to_f.days.ago]
    conditions.add ["#{Issue.table_name}.author_id = ?", user] if for_option == :author && user.present?
      
    issues = Issue.visible.all(:include => :assigned_to,
                               :order => "#{Issue.table_name}.updated_on DESC",
                               :conditions => conditions.conditions)

    return issues.group_by(&:assigned_to)
  end
  
end

