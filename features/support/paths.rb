def path_to(page_name)
  case page_name
  
  when /the homepage/i
    url_for(:controller => 'welcome')
  # Add more page name => path mappings here
  
  else
    raise "Can't find mapping from \"#{page_name}\" to a path."
  end
end
