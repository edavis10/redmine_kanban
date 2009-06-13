def path_to(page_name)
  case page_name
  
  when /homepage/i
    url_for(:controller => 'welcome')
  when /kanban page/i
    kanban_url
  when /plugin administration/i
    url_for(:controller => 'admin', :action => 'plugins')
  when /Kanban configuration page/i
    url_for(:controller => 'settings', :action => 'plugin', :id => 'redmine_kanban')
  else
    raise "Can't find mapping from \"#{page_name}\" to a path."
  end
end
