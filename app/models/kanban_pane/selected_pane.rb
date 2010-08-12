class KanbanPane::SelectedPane < KanbanPane
  def get_issues(options={})
    user = options.delete(:user)
    KanbanIssue.find_selected.find_for(user, options[:for])
  end
end

