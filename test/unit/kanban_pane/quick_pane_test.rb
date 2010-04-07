require File.dirname(__FILE__) + '/../../test_helper'

class KanbanPane::QuickPaneTest < ActiveSupport::TestCase

  context "#get_issues" do
    should_not_raise_an_exception_if_the_settings_are_missing do
      KanbanPane::QuickPane.new.get_issues
    end
  end

end
