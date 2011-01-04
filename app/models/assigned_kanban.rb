class AssignedKanban < Kanban
  def initialize(attributes={})
    super
    @for = [:assigned_to]
    @fill_incoming = true
    @fill_backlog = true
  end
  
end
