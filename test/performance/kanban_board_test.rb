require 'test_helper'
require 'performance_test_help'

# Performance logs
#
# 2010-08-10
# * Pre run: 962ms
# * Optimize get_users to use one query with include: 958ms
class KanbanBoardTest < ActionController::PerformanceTest
  def setup
    configure_plugin
    setup_kanban_issues
    setup_all_issues

    @public_project = Project.generate!(:is_public => true)
    @user = User.generate_with_protected!(:login => 'user', :password => 'password', :password_confirmation => 'password')
    @role = Role.generate!(:permissions => [:view_issues, :view_kanban, :edit_kanban])
    @member = Member.generate!({:principal => @user, :project => @public_project, :roles => [@role]})

    login_as 'user', 'password'
  end
  
  def test_kanban_board
    get "/kanban"
  end
end
