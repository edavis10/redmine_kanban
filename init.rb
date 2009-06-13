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
             'panes' => { }
           })
  
  menu(:top_menu,
       :kanban,
       {:controller => 'kanbans', :action => 'show'},
       :caption => :kanban_title)
end
