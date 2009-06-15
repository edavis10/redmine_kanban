class KanbansController < ApplicationController
  unloadable
  def show
    @settings = Setting.plugin_redmine_kanban
    @incoming_issues = get_incoming_issues
    @backlog_issues = get_backlog_issues
  end

  private
  def get_incoming_issues
    return Issue.visible.find(:all,
                              :limit => @settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => {:status_id => @settings['panes']['incoming']['status']})
  end

  def get_backlog_issues
    return Issue.visible.all(:limit => @settings['panes']['backlog']['limit'],
                             :order => "#{Issue.table_name}.created_on ASC",
                             :conditions => {:status_id => @settings['panes']['backlog']['status']})


  end
end
