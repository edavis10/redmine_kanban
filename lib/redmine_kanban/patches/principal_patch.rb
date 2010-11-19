module RedmineKanban
  module Patches
    module PrincipalPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          unless Principal.reflect_on_all_associations.collect(&:name).include?(:issues_assignments)
            has_many :issue_assignments, :class_name => 'Issue', :foreign_key => 'assigned_to_id'
          end

          named_scope :with_issue_assigned, lambda {
            {
              :include => :issue_assignments,
              :conditions => "#{Issue.table_name}.assigned_to_id IS NOT NULL"
            }
          }

        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
