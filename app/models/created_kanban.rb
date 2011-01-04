class CreatedKanban < Kanban
  def initialize(attributes={})
    super
    @for = [:author, :watcher]
  end
  
end
