module RedmineKanban
  # Patches Redmine's Issues dynamically.  Adds a +after_save+ filter.
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class 
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        after_save :update_kanban_from_issue
      end

    end
    
    module ClassMethods
    end
    
    module InstanceMethods
      # This will update the KanbanIssues associated to the issue
      def update_kanban_from_issue
        self.reload
        KanbanIssue.update_from_issue(self)
        return true
      end
    end    
  end
end
