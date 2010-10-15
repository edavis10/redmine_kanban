module KanbansHelper
  def name_to_css(name)
    name.gsub(' ','-').downcase
  end

  def jquery_dialog_div(title=:field_issue)
    "<div id='dialog-window' title='#{ l(title) }'></div>"
  end

  def render_pane_to_js(pane, user=nil)
    if Kanban.valid_panes.include?(pane)
      return render_to_string(:partial => pane, :locals => {:user => user })
    else
      ''
    end
  end

  # Returns the CSS class for jQuery to hook into.  Current users are
  # allowed to Drag and Drop items into their own list, but not other
  # people's lists
  def allowed_to_assign_staffed_issue_to(user)
    if allowed_to_manage? || User.current == user
      'allowed'
    else
      ''
    end
  end

  def over_pane_limit?(limit, counter)
    if !counter.nil? && !limit.nil? && counter.to_i >= limit.to_i # 0 based counter
      return 'over-limit'
    else
      return ''
    end
  end

  # Was the last journal with a note created by someone other than the
  # assigned to user?
  def updated_note_on_issue?(issue)
    if issue && issue.journals.present?
      last_journal_with_note = issue.journals.select {|journal| journal.notes.present?}.last
      last_journal_with_note && issue.assigned_to_id != last_journal_with_note.user_id
    end
  end

  def kanban_issue_css_classes(issue)
    css = 'kanban-issue ' + issue.css_classes
    if User.current.logged? && !issue.assigned_to_id.nil? && issue.assigned_to_id != User.current.id
      css << ' assigned-to-other'
    end
    css << ' issue-behind-schedule' if issue.behind_schedule?
    css << ' issue-overdue' if issue.overdue?
    css << ' parent-issue' if issue.root? && issue.children.count > 0
    css
  end

  def issue_icon_link(issue)
    if Setting.gravatar_enabled? && issue.assigned_to
      img = avatar(issue.assigned_to, {
                     :class => 'gravatar icon-gravatar',
                     :size => 10,
                     :title => l(:field_assigned_to) + ": " + issue.assigned_to.name
                   })
      link_to(img, :controller => 'issues', :action => 'show', :id => issue)
    else
      link_to(image_tag('ticket.png', :style => 'float:left;'), :controller => 'issues', :action => 'show', :id => issue)
    end
  end

  def column_configured?(column)
    case column
    when :unstaffed
      KanbanPane::IncomingPane.configured? || KanbanPane::BacklogPane.configured?
    when :selected
      KanbanPane::QuickPane.configured? || KanbanPane::SelectedPane.configured?
    when :staffed
      true # always
    end
  end

  # Calculates the width of the column.  Max of 96 since they need
  # some extra for the borders.
  def column_width(column)
    # weights of the columns
    column_ratios = {
      :unstaffed => 1,
      :selected => 1,
      :staffed => 4
    }
    return 0.0 if column == :unstaffed && !column_configured?(:unstaffed)
    return 0.0 if column == :selected && !column_configured?(:selected)
    
    visible = 0
    visible += column_ratios[:unstaffed] if column_configured?(:unstaffed)
    visible += column_ratios[:selected] if column_configured?(:selected)
    visible += column_ratios[:staffed] if column_configured?(:staffed)
    
    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end

  def my_kanban_column_width(column)
    column_ratios = {
      :project => 1,
      :testing => 1,
      :active => 1,
      :selected => 1,
      :backlog => 1
    }

    # Vertical column
    if column == :incoming
      return (KanbanPane::IncomingPane.configured? ? 100.0 : 0.0)
    end

    # Inside of Project, max width
    if column == :finished || column == :canceled
      return 100.0
    end

    return 0.0 if column == :active && !KanbanPane::ActivePane.configured?
    return 0.0 if column == :testing && !KanbanPane::TestingPane.configured?
    return 0.0 if column == :selected && !KanbanPane::SelectedPane.configured?
    return 0.0 if column == :backlog && !KanbanPane::BacklogPane.configured?

    visible = 0
    visible += column_ratios[:project]
    visible += column_ratios[:active] if KanbanPane::ActivePane.configured?
    visible += column_ratios[:testing] if KanbanPane::TestingPane.configured?
    visible += column_ratios[:selected] if KanbanPane::SelectedPane.configured?
    visible += column_ratios[:backlog] if KanbanPane::BacklogPane.configured?

    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end

  # Calculates the width of the column.  Max of 96 since they need
  # some extra for the borders.
  def staffed_column_width(column)
    # weights of the columns
    column_ratios = {
      :user => 1,
      :active => 2,
      :testing => 2,
      :finished => 2,
      :canceled => 2
    }
    return 0.0 if column == :active && !KanbanPane::ActivePane.configured?
    return 0.0 if column == :testing && !KanbanPane::TestingPane.configured?
    return 0.0 if column == :finished && !KanbanPane::FinishedPane.configured?
    return 0.0 if column == :canceled && !KanbanPane::CanceledPane.configured?

    visible = 0
    visible += column_ratios[:user]
    visible += column_ratios[:active] if KanbanPane::ActivePane.configured?
    visible += column_ratios[:testing] if KanbanPane::TestingPane.configured?
    visible += column_ratios[:finished] if KanbanPane::FinishedPane.configured?
    visible += column_ratios[:canceled] if KanbanPane::CanceledPane.configured?
    
    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end
    
  def issue_url(issue)
    url_for(:controller => 'issues', :action => 'show', :id => issue)
  end

  def showing_current_user_kanban?
    @user == User.current
  end

  # Renders the title for the "Incoming" project.  It can be linked as:
  # * New Issue jQuery dialog (user has permission to add issues)
  # * Link to the url configured in the plugin (plugin is configured with a url)
  # * No link at all
  def incoming_title
    if Setting.plugin_redmine_kanban['panes'].present? &&
        Setting.plugin_redmine_kanban['panes']['incoming'].present? &&
        Setting.plugin_redmine_kanban['panes']['incoming']['url'].present?
      href_url = Setting.plugin_redmine_kanban['panes']['incoming']['url']
    else
      href_url = ''
    end
    
    if User.current.allowed_to?(:add_issues, nil, :global => true)
       link_to(l(:kanban_text_incoming), href_url, :class => 'new-issue-dialog')
    elsif href_url.present?
      link_to(l(:kanban_text_incoming), href_url)
    else
      l(:kanban_text_incoming)
    end
  end

  def export_i18n_for_javascript
    strings = {
      'kanban_text_error_saving_issue' => l(:kanban_text_error_saving_issue),
      'kanban_text_issue_created_reload_to_see' => l(:kanban_text_issue_created_reload_to_see),
      'kanban_text_notice_reload' => l(:kanban_text_notice_reload)
    }

    javascript_tag("var i18n = #{strings.to_json}")
  end
  
  def viewed_user
    return @user if @user.present?
    return User.current
  end

  class UserKanbanDivHelper < BlockHelpers::Base
    include ERB::Util

    def initialize(options={})
      @column = options[:column]
      @user = options[:user]
      @project_id = options[:project_id]
    end

    def issues(issues)
      if issues.compact.empty? || issues.flatten.compact.empty?
        render :partial => 'kanbans/empty_issue'
      else
        render(:partial => 'kanbans/issue',
               :collection => issues.flatten,
               :locals => { :limit => Setting['plugin_redmine_kanban']["panes"][@column.to_s]["limit"].to_i })
      end
    end

    def display(body)
      content_tag(:div,
                  content_tag(:ol,
                              body,
                              :id => "#{@column}-issues-user-#{h(@user.id)}-project-#{h(@project_id)}", :class => "#{@column}-issues"),
                  :id => "#{@column}-#{h(@user.id)}-project-#{h(@project_id)}", :class => "pane equal-column #{@column} user-#{h(@user.id)}", :style => "width: #{ helper.my_kanban_column_width(@column)}%")
    end
    
  end
end
