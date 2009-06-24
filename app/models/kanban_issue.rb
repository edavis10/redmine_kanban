# A Kanban issue will Kanban specific information about an issue
# including it's state, position, and association.  #2607
class KanbanIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  acts_as_list

  validates_presence_of :state
  validates_presence_of :position

  def scope_condition
    "state = #{connection.quote(state)} AND user_id = #{connection.quote(user_id)}"
  end
end
