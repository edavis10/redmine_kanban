class KanbanPane::ActivePane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    projects = options.delete(:projects)

    users.inject({}) do |result, user|
      result[user] = if projects.present?
                       KanbanIssue.find_active(user.id).for_projects(projects)
                     else
                       KanbanIssue.find_active(user.id)
                     end
      result
    end
  end
end

