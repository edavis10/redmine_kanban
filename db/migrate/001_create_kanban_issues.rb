class CreateKanbanIssues < ActiveRecord::Migration
  def self.up
    create_table :kanban_issues do |t|
      t.column :user_id, :integer
      t.column :position, :integer
      t.column :issue_id, :integer
      t.column :state, :string
    end

    add_index :kanban_issues, :user_id
    add_index :kanban_issues, :issue_id
    add_index :kanban_issues, :state
  end
  
  def self.down
    drop_table :kanban_issues
  end
end
