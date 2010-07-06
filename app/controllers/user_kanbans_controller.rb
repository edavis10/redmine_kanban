class UserKanbansController < ApplicationController
  unloadable

  before_filter :require_login
  before_filter :authorize_global

  def show
  end
end
