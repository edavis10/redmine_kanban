class KanbanIssuesController < ApplicationController
  unloadable

  before_filter :require_js_format
  before_filter :authorize
  before_filter :setup_settings
  before_filter :find_issue, :except => [:new]
  before_filter :require_valid_from_pane, :except => [:new]

  def new
    @issue = Issue.new
     @allowed_projects = User.current.projects.all(:conditions =>
                                                   Project.allowed_to_condition(User.current, :add_issues))
    @project = @allowed_projects.detect {|p| p.id.to_s == params[:issue][:project_id]} if params[:issue] && params[:issue][:project_id]
    @project ||= @allowed_projects.first
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current, true)
    @priorities = IssuePriority.all

    respond_to do |format|
      format.html { render :text => '', :status => :not_acceptable }
      format.js { render :layout => false }
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
