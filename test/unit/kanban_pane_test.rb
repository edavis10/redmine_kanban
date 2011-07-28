require File.dirname(__FILE__) + '/../test_helper'

class KanbanPaneTest < ActiveSupport::TestCase

  context "#pane_order" do
    context "with standard pane order" do
      should "list the panes" do
        reconfigure_plugin({'reverse_pane_order' => '0'})
        assert_equal [:incoming, :backlog, :quick, :selected, :active, :testing, :finished, :canceled], KanbanPane.pane_order
      end
      
    end

    context "with reversed pane order" do
      should "list the panes in a semi-reversed order" do
        reconfigure_plugin({'reverse_pane_order' => '1'})
        assert_equal [:incoming, :finished, :canceled, :testing, :active, :selected, :quick, :backlog], KanbanPane.pane_order
      end
    end
    
  end

  context "#pane_order_reversed?" do
    should 'be false when the pane order reverse setting is not set' do
      reconfigure_plugin({'reverse_pane_order' => '0'})
      assert !KanbanPane.pane_order_reversed?
    end
    
    should 'be true when the pane order reverse setting is set' do
      reconfigure_plugin({'reverse_pane_order' => '1'})
      assert KanbanPane.pane_order_reversed?
    end
    
    should 'be false when the pane order reverse setting is not valid' do
      reconfigure_plugin({'reverse_pane_order' => 'bbq'})
      assert !KanbanPane.pane_order_reversed?
    end

    context "for users" do
      should 'be true when a user overrides the system setting'
      should 'be falue when a user overrides the system setting'
    end
    
  end
end
