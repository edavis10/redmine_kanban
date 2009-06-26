module KanbansHelper
  def name_to_css(name)
    name.gsub(' ','-').downcase
  end

  def render_pane_to_js(pane)
    if ["incoming","backlog","selected","active"].include?(pane)
      return render_to_string(:partial => pane, :locals => {:user => @user })
    else
      ''
    end
  end
end
