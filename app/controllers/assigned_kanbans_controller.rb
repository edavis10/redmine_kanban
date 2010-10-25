class AssignedKanbansController < ApplicationController
  unloadable

  helper :kanbans

  before_filter :require_login
  before_filter :authorize_global

  def show
    @user = User.find_by_id(params[:id]) || User.current
    # Block access to viewing other user's Kanban Requests
    # TODO: User.member_of(Group) would be a nice core change
    if @user != User.current && kanban_settings["management_group"] &&
        !User.current.group_ids.include?(kanban_settings["management_group"].to_i)
      render_403
      return
    end

    render :text => 'Hello Kanban'
  end

  private

  def kanban_settings
    @kanban_settings = Setting.plugin_redmine_kanban
  end
  helper_method :kanban_settings

end
