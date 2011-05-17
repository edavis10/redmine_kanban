class KanbanOverviewsController < ApplicationController
  unloadable

  helper :kanbans

  before_filter :require_login
  before_filter :authorize_global

  def show
    @kanban = OverviewKanban.new

    @projects_sorted_by_tree = []
    Project.project_tree(@kanban.projects) do |project, level|
      @projects_sorted_by_tree << project
    end

    respond_to do |format|
      format.html {}
    end
  end

  private

  def kanban_settings
    @kanban_settings = Setting.plugin_redmine_kanban
  end
  helper_method :kanban_settings

end
