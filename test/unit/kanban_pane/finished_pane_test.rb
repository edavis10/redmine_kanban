require File.dirname(__FILE__) + '/../../test_helper'

class KanbanPane::FinishedPaneTest < ActiveSupport::TestCase

  context "#get_issues" do
    should_not_raise_an_exception_if_the_settings_are_missing do
      KanbanPane::FinishedPane.new.get_issues
    end
  end

end
