ActionController::Routing::Routes.draw do |map|
  map.resource :kanban, :member => {:sync => :put} do |kanban|
    kanban.resources :user_kanbans, :as => 'users'
    kanban.resource :user_kanbans, :as => 'my-requests'
    kanban.resources :assigned_kanbans, :as => 'assigned-to'
    kanban.resource :assigned_kanbans, :as => 'my-assigned', :only => [:show]
  end
  map.resources :kanban_issues
end
