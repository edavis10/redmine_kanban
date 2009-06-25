require 'redmine'

Redmine::Plugin.register :redmine_kanban do
  name 'Kanban'
  author 'Eric Davis'
  url 'https://projects.littlestreamsoftware.com/'
  author_url 'http://www.littlestreamsoftware.com'
  description 'The Redmine Kanban plugin is used to manage issues according to the Kanban system of project management.'
  version '0.1.0'

  requires_redmine :version_or_higher => '0.8.0'

  settings(:partial => 'settings/kanban_settings',
           :default => {
             'panes' => {
               'incoming' => { 'status' => nil, 'limit' => 5},
               'backlog' => { 'status' => nil, 'limit' => 15},
               'selected' => { 'status' => nil, 'limit' => 8},
               'quick-tasks' => {'limit' => 5},
               'active' => { 'status' => nil, 'limit' => 5},
               'testing' => { 'status' => nil, 'limit' => 5}
             }
           })
  
  menu(:top_menu,
       :kanban,
       {:controller => 'kanbans', :action => 'show'},
       :caption => :kanban_title)
end
