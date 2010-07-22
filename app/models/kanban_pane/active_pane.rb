class KanbanPane::ActivePane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    projects = options.delete(:projects)
    method = options.delete(:for)

    users.inject({}) do |result, user|
      if method == :author
        result[user] = KanbanIssue.find_active.authored(user.id)
      else
        # Uses assigned to
        result[user] = KanbanIssue.find_active.assigned(user.id)
      end
      result
    end
  end
end

