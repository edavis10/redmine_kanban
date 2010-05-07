class KanbanIssuesController < ApplicationController
  unloadable

  before_filter :require_js_format
  before_filter :authorize
  before_filter :setup_settings
  before_filter :find_issue
  before_filter :require_valid_from_pane

  def edit
    respond_to do |format|
      format.html { render :text => '', :status => :not_acceptable }
      format.js { render :action => 'edit_incoming' }
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
