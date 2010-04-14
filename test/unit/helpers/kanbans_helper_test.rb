require File.dirname(__FILE__) + '/../../test_helper'

class KanbansHelperTest < HelperTestCase
  include ApplicationHelper
  include KanbansHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
  
  def setup
    super
    # Stub KanbanPane#settings so it will bypass the Settings cache.
    def KanbanPane.settings
      return Setting['plugin_redmine_kanban']
    end
  end

  def enable_pane(pane)
    new_panes = Setting['plugin_redmine_kanban']['panes'].merge({pane.to_s => {'status' => '1'}})
    reconfigure_plugin(Setting['plugin_redmine_kanban'].merge('panes' => new_panes))
  end

  context "#column_width" do
    setup do
      reconfigure_plugin({'panes' => {
                             'selected' => {},
                             'backlog' => {},
                             'quick-tasks' => {},
                             'testing' => {},
                             'active' => {},
                             'incoming' => {},
                             'finished' => {},
                             'canceled' => {}
                           }})
    end
    
    context "for unstaffed" do
      should "be 0 if unstaffed is disabled" do
        assert_equal 0, column_width(:unstaffed)
      end

      should "be 19.2 if unstaffed and staffed are enabled" do
        enable_pane(:incoming)
        enable_pane(:backlog)

        assert KanbanPane::IncomingPane.configured?
        assert KanbanPane::BacklogPane.configured?
        assert !KanbanPane::SelectedPane.configured?

        assert_equal 19.2, column_width(:unstaffed)
      end

      should "be 16.0 if unstaffed, selected, and staffed are enabled"  do
        enable_pane(:incoming)
        enable_pane(:backlog)
        enable_pane(:selected)

        assert KanbanPane::IncomingPane.configured?
        assert KanbanPane::BacklogPane.configured?
        assert KanbanPane::SelectedPane.configured?

        assert_equal 16.0, column_width(:unstaffed)
      end
    end

    context "for selected" do
      should "be 0 if unstaffed is disabled" do
        assert_equal 0, column_width(:selected)
      end

      should "be 19.2 if selected and staffed are enabled" do
        enable_pane(:selected)

        assert !KanbanPane::IncomingPane.configured?
        assert !KanbanPane::BacklogPane.configured?
        assert KanbanPane::SelectedPane.configured?

        assert_equal 19.2, column_width(:selected)
      end

      should "be 16.0 if unstaffed, selected, and staffed are enabled"  do
        enable_pane(:incoming)
        enable_pane(:backlog)
        enable_pane(:selected)

        assert KanbanPane::IncomingPane.configured?
        assert KanbanPane::BacklogPane.configured?
        assert KanbanPane::SelectedPane.configured?

        assert_equal 16.0, column_width(:selected)
      end
    end

    context "for staffed" do
      should "be 96 if only staffed is enabled" do
        assert_equal 96, column_width(:staffed)
      end
      
      should "be 76.8 if unstaffed and staffed are enabled" do
        enable_pane(:incoming)
        enable_pane(:backlog)

        assert KanbanPane::IncomingPane.configured?
        assert KanbanPane::BacklogPane.configured?

        assert_equal 76.8, column_width(:staffed)
      end

      should "be 76.8 if selected and staffed are enabled" do
        enable_pane(:selected)

        assert KanbanPane::SelectedPane.configured?

        assert_equal 76.8, column_width(:staffed)
      end

      should "be 64.0 if unstaffed, selected, and staffed are enabled" do
        enable_pane(:incoming)
        enable_pane(:backlog)
        enable_pane(:selected)

        assert KanbanPane::IncomingPane.configured?
        assert KanbanPane::BacklogPane.configured?
        assert KanbanPane::SelectedPane.configured?

        assert_equal 64.0, column_width(:staffed)
      end
      
    end
  end

end
