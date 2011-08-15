class Kanban
  attr_reader :incoming_pane, :backlog_pane, :quick_pane, :canceled_pane, :finished_pane, :active_pane, :testing_pane, :selected_pane
  
  attr_accessor :incoming_issues
  attr_accessor :quick_issues
  attr_accessor :backlog_issues
  attr_accessor :selected_issues
  attr_accessor :active_issues
  attr_accessor :testing_issues
  attr_accessor :finished_issues
  attr_accessor :canceled_issues
  attr_accessor :settings
  attr_accessor :users
  attr_accessor :user
  # How is this Kanban built:
  # * :author - by who created the issue
  # * :assigned_to - by who is assigned the issue
  # * :watcher - by who is watching the issue
  attr_accessor :for

  attr_accessor :fill_backlog
  attr_accessor :fill_incoming

  def initialize(attributes={})
    @user = attributes[:user]
    @for = attributes[:for].to_a
    @for = [:assigned_to] unless @for.present?
    @fill_backlog = attributes[:fill_backlog] || false
    @fill_incoming = attributes[:fill_incoming] || false
    @incoming_pane = KanbanPane::IncomingPane.new
    @backlog_pane = KanbanPane::BacklogPane.new
    @quick_pane = KanbanPane::QuickPane.new
    @canceled_pane = KanbanPane::CanceledPane.new
    @finished_pane = KanbanPane::FinishedPane.new
    @active_pane = KanbanPane::ActivePane.new
    @testing_pane = KanbanPane::TestingPane.new
    @selected_pane = KanbanPane::SelectedPane.new
    
    @settings = Setting.plugin_redmine_kanban
    @users = get_users
  end

  def self.non_kanban_issues_panes
     ["incoming","backlog", "quick","finished","canceled"]
  end

  def self.kanban_issues_panes
    ['selected','active','testing']
  end

  def self.valid_panes
    kanban_issues_panes + non_kanban_issues_panes
  end

  def self.staffed_panes
    ['active','testing','finished','canceled']
  end

  def incoming_issues
    @incoming_issues ||= incoming_pane.get_issues(:user => @user, :for => @for)
  end

  def quick_issues
    @quick_issues ||= quick_pane.get_issues
  end

  def backlog_issues(additional_options={})
    quick_issues # Needs to load quick_issues
    backlog_pane.get_issues({:exclude_ids => quick_issue_ids, :for => @for, :user => @user}.merge(additional_options))
  end

  def selected_issues
    @selected_issues ||= selected_pane.get_issues(:user => @user, :for => @for)
  end

  def active_issues
    @active_issues ||= active_pane.get_issues(:users => get_users, :for => @for)
  end

  def testing_issues
    @testing_issues ||= testing_pane.get_issues(:users => get_users, :for => @for)
  end

  def finished_issues
    @finished_issues ||= finished_pane.get_issues(:for => @for, :user => @user)
  end

  def canceled_issues
    @canceled_issues ||= canceled_pane.get_issues(:users => get_users, :for => @for, :user => @user)
  end

  # Display the testing issues filtered by user and/or project
  # * :testing - user and project
  # * :active - user and project
  # * :selected - project
  #
  # OPTIMIZE: could cache this to ivars
  [:testing, :active, :selected, :canceled, :finished].each do |pane|
    define_method("#{pane}_issues_for") {|options|
      options = {} if options.nil?
      project = options[:project]
      user = options[:user]

      case
      when [:testing, :active].include?(pane) # grouped by user
        all_kanban_issues = send("#{pane}_issues")[user]
        
      when [:selected, :canceled, :finished].include?(pane) # no grouping
        all_kanban_issues = send("#{pane}_issues")

      else
        all_kanban_issues = []
      end

      issues = filter_issues(all_kanban_issues, :project => project, :user => user)
    }
  end

  # Display the backlog issues filtered by user and/or project, sorted by
  # Priority
  #
  # Will fill to the pane limit with unassigned and assigned to other
  # issues
  # OPTIMIZE: could cache this to ivars
  # TODO: filtering is a mess
  def backlog_issues_for(options={})
    # Used to turn off fill_backlog on a per-call basis
    fill_backlog = options[:fill_backlog]
    fill_backlog = @fill_backlog if fill_backlog.nil?
    
    # Override the default backlog_issues finder
    backlog_issues_additional_options = {}
    if user = options[:user]
      backlog_issues_additional_options[:user] = user
    end
    
    if project = options[:project]
      # restricts the find to only specific projects, so limit is followed
      restrict_to_projects = project.self_and_descendants.collect(&:id)
      backlog_issues_additional_options[:project_ids] = restrict_to_projects
    end
    
    backlog_issues_found = backlog_issues(backlog_issues_additional_options)

    issues = filter_issues(backlog_issues_found, :project => project, :user => user)
    issues = issues.sort_by(&:priority) if issues.present?

    # Fill the backlog issues until the plugin limit
    if fill_backlog && issues.length < @settings['panes']['backlog']['limit'].to_i

      # Add some additional options for getting the fill
      fill_options = {}
      # Clears the user, all issues should be found.
      fill_options[:user] = nil
      # Adds extra exclude ids for issues that are in the backlog_issues already
      fill_options[:exclude_ids] = quick_issue_ids + issues.collect(&:id)
      # Sets the limit to be how many are still needed
      fill_options[:limit] = @settings['panes']['backlog']['limit'].to_i - issues.length

      backlog_issues_with_fill = backlog_issues(backlog_issues_additional_options.merge(fill_options))

      if backlog_issues_with_fill.present?
        fill_issues = filter_issues(backlog_issues_with_fill, :project => project, :user => nil)
        # Sort by priority but appended to existing issues
        # [High, Med, Low] + [High, Med, Low], not [High, High, Med, Med, Low, Low]
        fill_issues = fill_issues.sort_by(&:priority)
        issues += fill_issues
      end
      
    end

    issues
  end

  def incoming_issues_for(options={})
    issues = incoming_issues
    if @fill_incoming && issues.length < @settings['panes']['incoming']['limit'].to_i
      limit = @settings['panes']['incoming']['limit'].to_i - issues.length
      issues += incoming_pane.get_issues(:user => nil,
                                         :for => nil,
                                         :exclude_ids => issues.collect(&:id),
                                         :limit => limit)
    end
    
    issues
  end

  def get_users
    if @user
      @users = [@user]
    else
      role_id = @settings["staff_role"].to_i
      if role_id
        query_conditions = ARCondition.new
        query_conditions.add ["#{MemberRole.table_name}.role_id = ?", role_id]
        query_conditions.add "#{MemberRole.table_name}.member_id = #{Member.table_name}.id"
        query_conditions.add "#{Member.table_name}.user_id = #{User.table_name}.id"
        @users = User.active.all(:conditions => query_conditions.conditions,
                          :select => "users.*",
                          :joins => "LEFT  JOIN members ON members.user_id = users.id LEFT  JOIN projects ON projects.id = members.project_id LEFT  JOIN member_roles ON (members.id = member_roles.member_id) LEFT  JOIN roles ON (roles.id = member_roles.role_id) LEFT  JOIN member_roles member_roles_members ON member_roles_members.member_id = members.id")
      end
      @users ||= []
      @users = move_current_user_to_front
      @users << UnknownUser.instance
      @users.uniq!
      @users
    end
  end

  # Find all of the projects referenced on the KanbanIssue and Issues
  def projects
    unless @projects
      @projects = Project.all(:conditions => Project.allowed_to_condition(User.current, :view_issues))
      # User isn't a member but they created an issue which was moved out of their visibility
      @projects += Project.all(:include => :issues,
                               :conditions => ["#{Issue.table_name}.author_id = :user AND #{Project.table_name}.id NOT IN (:found_projects)", {:user => User.current.id, :found_projects => @projects.collect(&:id)}])

      @projects = roll_up_projects_to_project_level(@projects).uniq
    end
    @projects
  end

  def has_issues_for_project_and_user?(project, user)
    opts = {:user => user, :project => project}

    return true if opts[:project].respond_to?("fake_root?") && opts[:project].fake_root?

    # TODO: should be refactored to use enum#any?
    return true if testing_issues_for(opts).length > 0
    return true if active_issues_for(opts).length > 0
    return true if selected_issues_for(opts).length > 0
    return true if backlog_issues_for(opts.merge({:fill_backlog => false})).length > 0
    return false
  end
  
  def quick_issue_ids
    if quick_issues.present? && quick_issues.flatten.present?
      quick_issues.collect {|ary| ary[1] }.flatten.collect(&:id)
    else
      []
    end
  end

  def project_level
    unless @project_level
      @project_level = Setting.plugin_redmine_kanban['project_level'].to_i if Setting.plugin_redmine_kanban['project_level'].present?
      @project_level ||= 0
    end
    
    @project_level
  end

  def roll_up_projects?
    rollup = Setting.plugin_redmine_kanban['rollup'].to_i if Setting.plugin_redmine_kanban['rollup'].present?
    rollup == 1
  end

  def filter_issues(issues, filters = {})
    project_filter = filters[:project]
    user_filter = filters[:user]
    filter_user_on = @for
    
    # Support looking up the issue through a KanbanIssue
    actual_issues = issues.collect {|issue|
      issue.is_a?(Issue) ? issue : issue.issue
    }
    
    filtered_issues = actual_issues.select {|issue|

      if project_filter
        project_filter_passed = issue.for_project?(project_filter) || (roll_up_projects? && issue.for_project_descendant?(project_filter))
      else
        project_filter_passed = true # No filter
      end

      if user_filter
        user_filter_results = filter_user_on.collect do |user_attribute_filter|
          case user_attribute_filter
          when :author
            issue.author == user_filter
          when :assigned_to
            issue.assigned_to == user_filter
          when :watcher
            issue.watched_by?(user_filter)
          else
            false
          end          
        end

        user_filter_passed = user_filter_results.any?
      else
        user_filter_passed = true # No filter
      end

      project_filter_passed && user_filter_passed
    }
    filtered_issues ||= []
    filtered_issues

  end

  # Updates the Issue with +issue_id+ to change it's
  # * Status to the IssueStatus set for the +to+ pane
  # * Assignment to the +target_user+ on staffed panes
  def self.update_issue_attributes(issue_id, from, to, user=User.current, target_user=nil, extra_attributes = {})
    @settings = Setting.plugin_redmine_kanban

    issue = Issue.find_by_id(issue_id)

    if @settings['panes'][to] && @settings['panes'][to]['status']
      new_status = IssueStatus.find_by_id(@settings['panes'][to]['status'].to_i)
    end
      
    if issue && new_status
      issue.init_journal(user)
      issue.attributes = extra_attributes if extra_attributes
      issue.status = new_status

      if Kanban.staffed_panes.include?(to) && !target_user.nil? && target_user.is_a?(User)
        issue.assigned_to = target_user
      end

      return issue.save
    else
      return false
    end

  end

  # Updates +target_pane+ so that the KanbanIssues match +sorted_issues+
  def self.update_sorted_issues(target_pane, sorted_issues, user_id=nil)
    if Kanban.kanban_issues_panes.include?(target_pane)
      if sorted_issues.blank? && !target_pane.blank?
        KanbanIssue.destroy_all(:state => target_pane, :user_id => user_id)
      else
        # Remove items that are in the database but not in the
        # sorted_issues
        if user_id
          KanbanIssue.destroy_all(['state = ? AND user_id = ? AND issue_id NOT IN (?)',target_pane, user_id, sorted_issues])
        else
          KanbanIssue.destroy_all(['state = ? AND issue_id NOT IN (?)',target_pane, sorted_issues])
        end
          
        sorted_issues.each_with_index do |issue_id, zero_position|
          kanban_issue = KanbanIssue.find_by_issue_id(issue_id)
          if kanban_issue
            if kanban_issue.state != target_pane
              # Change state
              kanban_issue.send(target_pane.to_sym)
            end
            kanban_issue.user_id = user_id unless target_pane == 'selected'
            kanban_issue.position = zero_position + 1 # acts_as_list is 1 based
            kanban_issue.save
          else
            kanban_issue = KanbanIssue.new({:issue_id => issue_id,
                                             :state => target_pane,
                                             :position => (zero_position + 1)})
            kanban_issue.user_id = user_id unless target_pane == 'selected'
            kanban_issue.save
            # Need to resave since acts_as_list automatically moves a
            # new issue to the bottom on create
            kanban_issue.insert_at(zero_position + 1)
          end
        end
      end
    end
  end

  private

  def move_current_user_to_front
    if user = @users.delete(User.current)
      @users.unshift(user)
    else
      @users
    end
  end

  # Returns a list of projects that are higher up in the tree than project_level
  #
  # Recursive
  def roll_up_projects_to_project_level(projects)
    return projects unless roll_up_projects?
    return [root_project] if project_level == 0
    
    projects.inject([]) {|filtered, project|
      if project.level >= project_level
        filtered + roll_up_projects_to_project_level(project.ancestors)
      else
        filtered << project
      end
      filtered.uniq
    }
  end

  # Returns a mock project that acts as the "root" project, where
  # every other project descends from
  def root_project
    # Using a large rgt so this project wraps everything
    root_project = Project.new(:name => 'Projects',
                               :lft => 1, :rgt => 2147483647)
    def root_project.fake_root?
      true
    end
    def root_project.is_descendant_of?(project)
      false
    end
    def root_project.left
      1
    end
    def root_project.right
      2147483647
    end
    root_project
  end
end
