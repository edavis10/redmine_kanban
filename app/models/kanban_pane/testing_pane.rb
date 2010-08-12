class KanbanPane::TestingPane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    projects = options.delete(:projects)
    
    users.inject({}) do |result, user|
      result[user] = KanbanIssue.find_testing.find_for(user, options[:for])
      result
    end
  end
end

