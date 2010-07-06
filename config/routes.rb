ActionController::Routing::Routes.draw do |map|
  map.resource :kanban, :member => {:sync => :put} do |kanban|
    kanban.resources :user_kanbans, :as => 'users'
    kanban.resource :user_kanbans, :as => 'my-requests'
  end
  map.resources :kanban_issues
end
