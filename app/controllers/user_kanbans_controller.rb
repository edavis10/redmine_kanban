class UserKanbansController < ApplicationController
  unloadable

  def show
    render :text => 'hi'
  end
end
