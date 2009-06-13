module KanbansHelper
  def incoming_project_configured?
    @settings &&
      @settings['incoming_project'] &&
      !@settings['incoming_project'].blank?
  end

end
