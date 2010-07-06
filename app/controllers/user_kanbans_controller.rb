class UserKanbansController < ApplicationController
  unloadable

  helper :kanbans

  before_filter :require_login
  before_filter :authorize_global

  def show
    @user = User.find_by_id(params[:id]) || User.current
    # Block access to viewing other user's Kanban Requests
    if @user != User.current && !User.current.allowed_to?(:manage_kanban, nil, :global => true)
      render_403
    end
  end

  def create
    user_id = if params[:user] && params[:user][:id]
                params[:user][:id]
              else
                User.current.id
              end
    redirect_to kanban_user_kanban_path(:id => user_id)
  end
end
