ActionController::Routing::Routes.draw do |map|
  map.resource :kanban, :member => {:sync => :put}
end
