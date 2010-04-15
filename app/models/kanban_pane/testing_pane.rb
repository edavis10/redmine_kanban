class KanbanPane::TestingPane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    
    users.inject({}) do |result, user|
      result[user] = KanbanIssue.find_testing(user.id)
      result
    end
  end
end

