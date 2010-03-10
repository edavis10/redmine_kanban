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

  def pane_configured?(pane)
    (@settings['panes'][pane] && !@settings['panes'][pane]['status'].blank?)
  end

  def kanban_issue_css_classes(issue)
    css = 'kanban-issue ' + issue.css_classes
    if User.current.logged? && !issue.assigned_to_id.nil? && issue.assigned_to_id != User.current.id
      css << ' assigned-to-other'
    end
    css
  end

  def issue_icon_link(issue)
    link_to(image_tag('ticket.png'), :controller => 'issues', :action => 'show', :id => issue)
  end
end
