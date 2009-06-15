class KanbansController < ApplicationController
  unloadable
  def show
    @settings = Setting.plugin_redmine_kanban
    @incoming_issues = get_incoming_issues
  end

  private
  def get_incoming_issues
    return Issue.visible.find(:all,
                              :limit => @settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => {:status_id => @settings['panes']['incoming']['status']})
  end
end
