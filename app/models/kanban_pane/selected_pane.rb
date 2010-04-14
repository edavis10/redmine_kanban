class KanbanPane::SelectedPane < KanbanPane
  def get_issues(options={})
    KanbanIssue.find_selected
  end
end

