module KanbansHelper
  def name_to_css(name)
    name.gsub(' ','-').downcase
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

  def pane_configured?(pane)
    (@settings['panes'] && @settings['panes'][pane] && !@settings['panes'][pane]['status'].blank?)
  end

  def display_pane?(pane)
    if pane == 'quick-tasks'
      pane_configured?('backlog') &&
        @settings['panes']['quick-tasks']['limit'].present? &&
        @settings['panes']['quick-tasks']['limit'].to_i > 0
    else
      pane_configured?(pane)
    end
  end

  def kanban_issue_css_classes(issue)
    css = 'kanban-issue ' + issue.css_classes
    if User.current.logged? && !issue.assigned_to_id.nil? && issue.assigned_to_id != User.current.id
      css << ' assigned-to-other'
    end
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
      link_to(image_tag('ticket.png'), :controller => 'issues', :action => 'show', :id => issue)
    end
  end

  def column_configured?(column)
    case column
    when :unstaffed
      pane_configured?('incoming') || pane_configured?('backlog')
    when :selected
      display_pane?('quick-tasks') || pane_configured?('selected')
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
    return 0.0 if column == :active && !pane_configured?(:active)
    return 0.0 if column == :testing && !pane_configured?(:testing)
    return 0.0 if column == :finished && !pane_configured?(:finished)
    return 0.0 if column == :canceled && !pane_configured?(:canceled)

    visible = 0
    visible += column_ratios[:user]
    visible += column_ratios[:active] if pane_configured?(:active)
    visible += column_ratios[:testing] if pane_configured?(:testing)
    visible += column_ratios[:finished] if pane_configured?(:finished)
    visible += column_ratios[:canceled] if pane_configured?(:canceled)
    
    return ((column_ratios[column].to_f / visible) * 96).round(2)
  end
    
  def issue_url(issue)
    url_for(:controller => 'issues', :action => 'show', :id => issue)
  end
end
