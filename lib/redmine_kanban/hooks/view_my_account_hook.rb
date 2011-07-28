module RedmineKanban
  module Hooks
    class ViewMyAccountHook < Redmine::Hook::ViewListener

      render_on(:view_my_account, :partial => 'my/kanban', :layout => false)

    end
  end
end
