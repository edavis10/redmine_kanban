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
        after_destroy :remove_kanban_issues

        # Add visible to Redmine 0.8.x
        unless respond_to?(:visible)
          named_scope :visible, lambda {|*args| { :include => :project,
              :conditions => Project.allowed_to_condition(args.first || User.current, :view_issues) } }
        end

        named_scope :due_between, lambda {|a, b|
          {
            :conditions => ["#{Issue.table_name}.due_date > :start and #{Issue.table_name}.due_date <= :end",
                            {
                              :start => a,
                              :end => b
                            }]
          }
        }

        named_scope :due_sooner_than, lambda {|a|
          {
            :conditions => ["#{Issue.table_name}.due_date < ?", a]
          }

        }

        named_scope :assigned_to, lambda {|user|
          {
            :conditions => ["#{Issue.table_name}.assigned_to_id = (?)", user.id]
          }
        }

        named_scope :created_by, lambda {|user|
          {
            :conditions => ["#{Issue.table_name}.author_id = (?)", user.id]
          }
        }
        
      end

    end
    
    module ClassMethods
      # Brute force update :)
      def sync_with_kanban
        Issue.all.each do |issue|
          KanbanIssue.update_from_issue(issue)
        end
      end

    end
    
    module InstanceMethods
      # This will update the KanbanIssues associated to the issue
      def update_kanban_from_issue
        self.reload
        KanbanIssue.update_from_issue(self)
        return true
      end

      def remove_kanban_issues
        KanbanIssue.destroy_all(['issue_id = (?)', self.id]) if self.id
      end

      # Returns true if the issue is overdue
      def overdue?
        !due_date.nil? && (due_date < Date.today) && !status.is_closed?
      end
      
      # Is the amount of work done less than it should for the due date
      def behind_schedule?
        return false if start_date.nil? || due_date.nil?
        done_date = start_date + ((due_date - start_date+1)* done_ratio/100).floor
        return done_date <= Date.today
      end
    end    
  end
end
