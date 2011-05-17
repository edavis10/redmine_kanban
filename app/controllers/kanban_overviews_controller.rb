class KanbanOverviewsController < ApplicationController
  unloadable

  helper :kanbans

  before_filter :require_login
  before_filter :authorize_global

  def show
  end

  private

  def kanban_settings
    @kanban_settings = Setting.plugin_redmine_kanban
  end
  helper_method :kanban_settings

end
