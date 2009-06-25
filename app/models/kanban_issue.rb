require 'aasm'

# A Kanban issue will Kanban specific information about an issue
# including it's state, position, and association.  #2607
class KanbanIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue
  belongs_to :user

  acts_as_list

  # For acts_as_list
  def scope_condition
    "state = #{connection.quote(state)} AND user_id = #{connection.quote(user_id)}"
  end

  validates_presence_of :position

  # States
  include AASM
  aasm_column :state
  aasm_initial_state :none

  aasm_state :none
  aasm_state :selected, :enter => :remove_user
  aasm_state :active
  aasm_state :testing

  aasm_event :selected do
    transitions :to => :selected, :from => [:none, :active, :testing]
  end

  aasm_event :active do
    transitions :to => :active, :from => [:none, :selected, :testing]
  end

  aasm_event :testing do
    transitions :to => :testing, :from => [:none, :selected, :active]
  end

  named_scope :find_selected, lambda {
    limit = Setting['plugin_redmine_kanban']["panes"]["selected"]["limit"].to_i
    {
      :limit => limit,
      :order => 'position ASC',
      :conditions => { :user_id => nil, :state => 'selected'}
    }
  }
  
  def remove_user
    self.user = nil
    save!
  end
end
