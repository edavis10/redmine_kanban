class KanbanPane::TestingPane < KanbanPane
  def get_issues(options={})
    users = options.delete(:users)
    
    issues = {}
    users.each do |user|
      issues[user] = KanbanIssue.find_testing(user.id)
    end unless users.blank?
    issues
  end
end

