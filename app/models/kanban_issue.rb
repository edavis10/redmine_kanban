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

  # Named with a find_ prefix becasue of the name conflict with the
  # state transitions.
  named_scope :find_selected, lambda {
    limit = Setting['plugin_redmine_kanban']["panes"]["selected"]["limit"].to_i
    {
      :limit => limit,
      :order => 'position ASC',
      :conditions => { :user_id => nil, :state => 'selected'}
    }
  }

  named_scope :find_active, lambda { |user_id|
    limit = Setting['plugin_redmine_kanban']["panes"]["active"]["limit"].to_i
    {
      :limit => limit,
      :order => 'user_id ASC, position ASC',
      :conditions => { :user_id => user_id, :state => 'active'}
    }
  }

  named_scope :find_testing, lambda { |user_id|
    limit = Setting['plugin_redmine_kanban']["panes"]["testing"]["limit"].to_i
    {
      :limit => limit,
      :order => 'user_id ASC, position ASC',
      :conditions => { :user_id => user_id, :state => 'testing'}
    }
  }
  
  def remove_user
    self.user = nil
    save!
  end
end
