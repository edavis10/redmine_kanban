# A Kanban issue will Kanban specific information about an issue
# including it's state, position, and association.  #2607
class KanbanIssue < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  validates_presence_of :state
  validates_presence_of :position
end
