# Wrappers around the Redmine core API changes between versions
module RedmineKanban
  module KanbanCompatibility
    class IssuePriority
      def self.klass
        if defined? ::IssuePriority
          ::IssuePriority
        else
          ::Enumeration
        end
      end
    end
  end
end
