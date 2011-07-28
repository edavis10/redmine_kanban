module RedmineKanban
  module Patches
    module UserPreferencePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          def kanban_reverse_pane_order
            self[:kanban_reverse_pane_order]
          end

          def kanban_reverse_pane_order=(value)
            self[:kanban_reverse_pane_order] = (value == "1") # convert to bool
          end
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
