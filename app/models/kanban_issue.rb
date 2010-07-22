# A Kanban issue will Kanban specific information about an issue
# including it's state, position, and association.  #2607
class KanbanIssue < ActiveRecord::Base
  unloadable

  belongs_to :issue
  belongs_to :user

  acts_as_list

  delegate :project, :to => :issue, :allow_nil => true
  
  # For acts_as_list
  def scope_condition
    if user_id
      "state = #{connection.quote(state)} AND user_id = #{connection.quote(user_id)}"
    else
      "state = #{connection.quote(state)} AND user_id IS NULL"
    end
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

  # Named with a find_ prefix because of the name conflict with the
  # state transitions.
  named_scope :find_selected, lambda {
    {
      :order => 'position ASC',
      :conditions => { :user_id => nil, :state => 'selected'}
    }
  }

  named_scope :find_active, lambda {
    {
      :order => 'user_id ASC, position ASC',
      :conditions => { :state => 'active'}
    }
  }

  named_scope :find_testing, lambda {
    {
      :order => 'user_id ASC, position ASC',
      :conditions => { :state => 'testing'}
    }
  }

  named_scope :assigned, lambda {|user_id|
    # Unknown users
    if user_id && user_id <= 0
      user_id = nil
    end
    {
      :conditions => { :user_id => user_id}
    }
  }

  named_scope :authored, lambda {|user_id|
    # Unknown users
    if user_id && user_id <= 0
      user_id = nil
    end
    {
      :conditions => ["#{Issue.table_name}.author_id = ?", user_id],
      :include => :issue
    }
  }

  named_scope :for_projects, lambda { |projects|
    project_ids = projects.collect(&:id)

    {
      :conditions => ["#{Issue.table_name}.project_id IN (?)", project_ids],
      :include => :issue
    }
  }
  
  def remove_user
    self.user = nil
    save!
  end

  # Called when an issue is updated.  This will create, remove, or
  # modify a KanbanIssue based on an Issue's status change
  def self.update_from_issue(issue)
    return true if issue.nil?
    if self.configured_statuses.include? issue.status.id.to_s
      kanban_issue = KanbanIssue.find_or_initialize_by_issue_id(issue.id)
      kanban_issue.issue_id = issue.id
      kanban_issue.state = pane_for_status(issue.status)

      if kanban_issue.new_record?
        kanban_issue.position = 0
      end

      if ['active','testing'].include? kanban_issue.state
        # TODO: Possbile to create KanbanIssue with a null user if the
        # Issue has no user assigned and is moved to a staffed pane manually
        kanban_issue.user = issue.assigned_to unless issue.assigned_to.nil?
      end
      
      return kanban_issue.save
    else
      KanbanIssue.destroy_all(['issue_id = ?', issue.id])
    end
    return true
  end

  def for_project?(project)
    self.project == project
  end

  private
  def self.configured_statuses
    valid_statuses = []
    Setting.plugin_redmine_kanban['panes'].each do |pane, options|
      if Kanban.kanban_issues_panes.include?(pane)
        valid_statuses << options["status"].to_s
      end
    end
    valid_statuses
  end

  def self.pane_for_status(status)
    Setting.plugin_redmine_kanban['panes'].each do |pane, options|
      if options['status'] && options['status'].to_i == status.id
        return pane
      end
    end
  end
end
