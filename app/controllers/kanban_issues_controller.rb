class KanbanIssuesController < ApplicationController
  unloadable

  before_filter :authorize
  before_filter :setup_settings

  def edit
    render :text => 'hi'
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
end
