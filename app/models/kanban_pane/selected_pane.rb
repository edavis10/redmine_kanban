class KanbanPane::SelectedPane < KanbanPane
  def get_issues(options={})
    if options[:for] == :author
      user = options.delete(:user)
      KanbanIssue.find_selected.authored(user.id)
    else
      KanbanIssue.find_selected
    end
  end
end

