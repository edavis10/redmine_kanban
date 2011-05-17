class OverviewKanban < Kanban
  def initialize(attributes={})
    super
    @for = [:assigned_to]
    @fill_incoming = false
    @fill_backlog = true
  end

  def get_users
    u = super
    u.reject {|user| user.is_a?(UnknownUser) }
  end
end
