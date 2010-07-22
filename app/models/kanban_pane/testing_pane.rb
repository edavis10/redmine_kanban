class KanbanPane::TestingPane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    projects = options.delete(:projects)
    method = options.delete(:for)
    
    users.inject({}) do |result, user|
      if method == :author
        result[user] = KanbanIssue.find_testing.authored(user.id)
      else
        # Uses assigned to
        result[user] = KanbanIssue.find_testing.assigned(user.id)
      end
      result
    end
  end
end

