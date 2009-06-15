module KanbansHelper
  def name_to_css(name)
    name.gsub(' ','-').downcase
  end
end
