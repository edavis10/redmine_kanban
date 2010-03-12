require 'redmine'

# Patches to the Redmine core.
require 'dispatcher'

Dispatcher.to_prepare :redmine_kanban do
  require_dependency 'issue'
  # Guards against including the module multiple time (like in tests)
  # and registering multiple callbacks
  unless Issue.included_modules.include? RedmineKanban::IssuePatch
    Issue.send(:include, RedmineKanban::IssuePatch)
  end
end


Redmine::Plugin.register :redmine_kanban do
  name 'Kanban'
  author 'Eric Davis'
  url 'https://projects.littlestreamsoftware.com/projects/redmine-kanban'
  author_url 'http://www.littlestreamsoftware.com'
  description 'The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management.'
  version '0.1.1'

  requires_redmine :version_or_higher => '0.8.0'

  permission(:view_kanban, {:kanbans => [:show]})
  permission(:edit_kanban, {:kanbans => [:update]})
  permission(:manage_kanban, {})
  
  settings(:partial => 'settings/kanban_settings',
           :default => {
             'panes' => {
               'incoming' => { 'status' => nil, 'limit' => 5},
               'backlog' => { 'status' => nil, 'limit' => 15},
               'selected' => { 'status' => nil, 'limit' => 8},
               'quick-tasks' => {'limit' => 5},
               'active' => { 'status' => nil, 'limit' => 5},
               'testing' => { 'status' => nil, 'limit' => 5},
               'finished' => {'status' => nil, 'limit' => 7},
               'canceled' => {'status' => nil, 'limit' => 7}
             }
           })
  
  menu(:top_menu,
       :kanban,
       {:controller => 'kanbans', :action => 'show'},
       :caption => :kanban_title,
       :if => Proc.new {
         User.current.allowed_to?(:view_kanban, nil, :global => true)
       })
end
