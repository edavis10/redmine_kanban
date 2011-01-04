class KanbanPane::CanceledPane < KanbanPane
  def get_issues(options={})
    return {} if missing_settings('canceled')
    for_option = options.delete(:for)
    user = options.delete(:user)
    user_id = user ? user.id : nil

    status_id = settings['panes']['canceled']['status']
    days = settings['panes']['canceled']['limit'] || 7

    conditions = ''
    conditions << " #{Issue.table_name}.status_id = :status"
    conditions << " AND #{Issue.table_name}.updated_on > :days"
    conditions = merge_for_option_conditions(conditions, for_option) if user.present?
    
    issues = Issue.visible.all(:include => [:assigned_to, :watchers],
                               :order => "#{Issue.table_name}.updated_on DESC",
                               :conditions => [conditions, {
                                                 :status => status_id,
                                                 :days => days.to_f.days.ago,
                                                 :user => user_id
                                               }])

  end
  
end

