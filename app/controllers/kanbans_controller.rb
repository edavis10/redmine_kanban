class KanbansController < ApplicationController
  unloadable
  helper :kanbans
  include KanbansHelper
  
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
    update_sorted_issues(@from, params[:from_issue])
    update_sorted_issues(@to, params[:to_issue])
    saved = change_issue_status(params[:issue_id], params[:from], params[:to], User.current)

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
                                                       'from' => render_pane_to_js(@from),
                                                       'to' => render_pane_to_js(@to)
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
  def change_issue_status(issue, from, to, user)
    issue = Issue.find_by_id(issue)

    if @settings['panes'][to] && @settings['panes'][to]['status']
      new_status = IssueStatus.find_by_id(@settings['panes'][to]['status'])
    end
      
    if issue && new_status
      issue.init_journal(user)
      issue.status = new_status
      return issue.save
    end
  end

  def update_sorted_issues(target_pane, sorted_issues)
    if ['selected'].include?(target_pane)
      sorted_issues.each_with_index do |issue_id, zero_position|
        kanban_issue = KanbanIssue.find_by_issue_id(issue_id)
        if kanban_issue
          if kanban_issue.state != target_pane
            # Change state
            kanban_issue.send(:target_pane)
          end
          kanban_issue.position = zero_position + 1 # acts_as_list is 1 based
          kanban_issue.save
          kanban_issue.reload
        else
          kanban_issue = KanbanIssue.new
          kanban_issue.issue_id = issue_id
          kanban_issue.state = target_pane
          kanban_issue.position = (zero_position + 1)
          kanban_issue.save
          # Need to resave since acts_as_list automatically moves a
          # new issue to the bottom on create
          kanban_issue.insert_at(zero_position + 1)
        end
        
      end
    end
  end
end
