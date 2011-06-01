class KanbanOverviewsController < ApplicationController
  unloadable

  helper :kanbans

  before_filter :require_login
  before_filter :authorize_global

  def show
    @kanban = OverviewKanban.new

    @projects_sorted_by_tree = []
    Project.project_tree(@kanban.projects) do |project, level|
      next if kanban_settings['incoming_projects'].present? && kanban_settings['incoming_projects'].include?(project.id.to_s)
      @projects_sorted_by_tree << project
    end

    # TODO: check user params/visibility
    @user = User.find_by_id(params[:user]) || User.current
    @kanban.user = @user if @user.present?
    project = Project.visible.find(params[:project]) if params[:project].present?

    respond_to do |format|
      format.html {}
      format.js { render :partial => 'kanbans/user_kanban_div', :locals => {:user => @user, :kanban => @kanban, :column => params[:column], :project => project}}

    end
  end

  private

  def kanban_settings
    @kanban_settings = Setting.plugin_redmine_kanban
  end
  helper_method :kanban_settings

end
