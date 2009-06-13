class KanbansController < ApplicationController
  unloadable
  def show
    @settings = Setting.plugin_redmine_kanban
  end
end
