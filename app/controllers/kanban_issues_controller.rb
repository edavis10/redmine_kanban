class KanbanIssuesController < ApplicationController
  unloadable

  before_filter :require_js_format
  before_filter :authorize
  before_filter :setup_settings
  before_filter :find_issue, :except => [:new]
  before_filter :require_valid_from_pane, :except => [:new, :show]

  helper :kanbans
  helper :issues
  helper :watchers
  helper :projects
  helper :custom_fields
  helper :attachments
  helper :journals
  helper :issue_relations
  helper :timelog
  
  def new
    @issue = Issue.new(:status => IssueStatus.default)
    @issue.author_login = User.current.login if @issue.respond_to?(:author_login)
    valid_incoming_projects_conditions = ARCondition.new(Project.allowed_to_condition(User.current, :add_issues))
    if @settings['panes'].present? && @settings['panes']['incoming'].present? && @settings['panes']['incoming']['excluded_projects'].present?
      valid_incoming_projects_conditions.add(["#{Project.table_name}.id IN (?)", @settings['panes']['incoming']['excluded_projects']])
    end
                                                         
    @allowed_projects = User.current.projects.all(:conditions => valid_incoming_projects_conditions.conditions)
                                                   
    @project = @allowed_projects.detect {|p| p.id.to_s == params[:issue][:project_id]} if params[:issue] && params[:issue][:project_id]
    @project ||= @allowed_projects.first
    @issue.project ||= @project
    # Tracker must be set before custom field values
    @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first) if @project
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
    @priorities = IssuePriority.all

    respond_to do |format|
      format.html { render :text => '', :status => :not_acceptable }
      format.js { render :layout => false }
    end
  end

  def show
    @project = @issue.project
    # journals/aaj compatiblity
    if ChiliProject::Compatibility.using_acts_as_journalized?
      @journals = @issue.journals.find(:all, :include => [:user], :order => "#{Journal.table_name}.created_at ASC")
    else
      @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    end
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.all
    @time_entry = TimeEntry.new

    respond_to do |format|
      format.html { render :text => '', :status => :not_acceptable }
      format.js {
        # Redmine only uses a single template so render that template to a
        # string first, then embed that string into our custom template. Meta!
        @core_content = render_to_string(:layout => false, :template => 'issues/show.rhtml')
        render :layout => false
      }
    end

  end

  def edit
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @allowed_projects = Issue.allowed_target_projects_on_move
    @allowed_projects.reject! {|p| @settings['panes']['incoming']['excluded_projects'] && @settings['panes']['incoming']['excluded_projects'].include?(p.id.to_s) }
    
    @priorities = IssuePriority.all
    @priorities.reject! {|p| @settings['panes']['incoming']['excluded_priorities'] && @settings['panes']['incoming']['excluded_priorities'].include?(p.id.to_s) }
    
    respond_to do |format|
      format.html { render :text => '', :status => :not_acceptable }
      format.js { render :action => 'edit_incoming', :layout => false }
    end
  end

  private
  # Override the default authorize and add in the global option. This will allow
  # the user in if they have any roles with the correct permission
  def authorize(ctrl = params[:controller], action = params[:action])
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, nil, { :global => true})
    allowed ? true : deny_access
  end

  def setup_settings
    @settings = Setting.plugin_redmine_kanban
  end

  # Find the requested issue.
  #
  # Also checks the permissions by using Issue#visible
  def find_issue
    @issue = Issue.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def require_valid_from_pane
    unless params[:from_pane] == 'incoming'
      render_404
    end
  end

  def require_js_format
    unless params[:format] == 'js'
      render_404
    end
  end

  # Override the core to allow 'js' format
  # TODO: submit to Redmine core
  def render_404
    if params[:format] == 'js'
      respond_to do |format|
        format.js { head 404 }
      end
      return false
    else
      super
    end

  end
end
