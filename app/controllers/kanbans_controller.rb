class KanbansController < ApplicationController
  unloadable
  helper :kanbans
  include KanbansHelper

  before_filter :authorize

  def show
    @settings = Setting.plugin_redmine_kanban
    @kanban = Kanban.find
    @incoming_issues = @kanban.incoming_issues
    @quick_issues = @kanban.quick_issues
    @backlog_issues = @kanban.backlog_issues
    @selected_issues = @kanban.selected_issues
  end

  def update
    @settings = Setting.plugin_redmine_kanban
    @from = params[:from]
    @to = params[:to]
    @from_user_id, @from_user, @to_user_id, @to_user =  *user_and_user_id

    Kanban.update_sorted_issues(@to, params[:to_issue], @to_user_id) if Kanban.kanban_issues_panes.include?(@to)

    saved = Kanban.update_issue_attributes(params[:issue_id], params[:from], params[:to], User.current, @to_user)

    @kanban = Kanban.find
    @incoming_issues = @kanban.incoming_issues
    @quick_issues = @kanban.quick_issues
    @backlog_issues = @kanban.backlog_issues
    @selected_issues = @kanban.selected_issues
    respond_to do |format|

      if saved
        format.html {
          flash[:notice] = l(:kanban_text_saved)
          redirect_to kanban_path
        }
        format.js {
          render :text => ActiveSupport::JSON.encode({
                                                       'from' => render_pane_to_js(@from, @from_user),
                                                       'to' => render_pane_to_js(@to, @to_user),
                                                       'additional_pane' => render_pane_to_js(params[:additional_pane])
                                                     })
        }
      else
        format.html {
          flash[:error] = l(:kanban_text_error_saving)
          redirect_to kanban_path
        }
        format.js { 
          render({:text => ({}.to_json), :status => :bad_request})
        }
      end
    end
  end

  private
  # Override the default authorize and add in the global option. This will allow
  # the user in if they have any roles with the correct permission
  def authorize(ctrl = params[:controller], action = params[:action])
    allowed = User.current.allowed_to?({:controller => ctrl, :action => action}, nil, { :global => true})
    allowed ? true : deny_access
  end

  helper_method :allowed_to_edit?
  def allowed_to_edit?
    User.current.allowed_to?({:controller => params[:controller], :action => 'update'}, nil, :global => true)
  end

  helper_method :allowed_to_manage?
  def allowed_to_manage?
    User.current.allowed_to?(:manage_kanban, nil, :global => true)
  end

  # Sets @user and @user_id based on the parameters
  def user_and_user_id
    from_user_id = nil
    from_user = nil
    to_user_id = nil
    to_user = nil

    
    case params[:from_user_id]
    when 'null' # Javascript nulls
      from_user_id = nil
      from_user = nil
    when '0' # Unknown user
      from_user_id = 0
      from_user = UnknownUser.instance
    else
      from_user_id = params[:from_user_id]
      from_user = User.find_by_id(from_user_id) # only needed for user specific views
    end

    case params[:to_user_id]
    when 'null' # Javascript nulls
      to_user_id = nil
      to_user = nil
    when '0' # Unknown user
      to_user_id = 0
      to_user = UnknownUser.instance
    else
      to_user_id = params[:to_user_id]
      to_user = User.find_by_id(to_user_id) # only needed for user specific views
    end

    return [from_user_id, from_user, to_user_id, to_user]
  end
end
