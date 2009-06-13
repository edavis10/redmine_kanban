def path_to(page_name)
  case page_name
  
  when /homepage/i
    url_for(:controller => 'welcome')
  
  else
    raise "Can't find mapping from \"#{page_name}\" to a path."
  end
end
