class KanbansController < ApplicationController
  unloadable
  def show
    @settings = Setting.plugin_redmine_kanban
    @incoming_issues = get_incoming_issues
  end

  private
  def get_incoming_issues
    incoming_project = Project.find_by_id(@settings['incoming_project'])
    if incoming_project
      return incoming_project.issues.find(:all,
                                          :limit => @settings['panes']['incoming']['limit'],
                                          :order => 'created_on ASC',
                                          :conditions => {:status_id => @settings['panes']['incoming']['status']})
    end
  end
end
