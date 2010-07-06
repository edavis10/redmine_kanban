require 'test_helper'

class RoutingTest < ActionController::IntegrationTest
  should_route :get, "/kanban", :controller => 'kanbans', :action => 'show'
  should_route :put, "/kanban", :controller => 'kanbans', :action => 'update'
  should_route :put, "/kanban.js", :controller => 'kanbans', :action => 'update', :format => 'js'
  should_route :put, "/kanban/sync", :controller => 'kanbans', :action => 'sync'

  should_route :get, "/kanban_issues/100/edit.js", :controller => 'kanban_issues', :action => 'edit', :id => 100, :format => 'js'

  should_route :get, "/kanban/my-requests", :controller => 'user_kanbans', :action => 'show'
  should_route :get, "/kanban/users/100", :controller => 'user_kanbans', :action => 'show', :id => 100
end
