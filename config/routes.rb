ActionController::Routing::Routes.draw do |map|
  map.resource :kanban, :member => {:sync => :put}
  map.resources :kanban_issues
end
