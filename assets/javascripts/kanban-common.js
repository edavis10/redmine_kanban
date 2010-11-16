(function($) {
  Kanban = {
    watched_issue: false,

    registerAjaxIndicator: function() {
      $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
      $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

    },

    // Register callbacks for the New Issue popup form
    registerNewIssueCallbacks: function() {
      $('#issue_project_id').change(function() {
        $('#dialog-window').load('/kanban_issues/new.js', $('#issue-form').serialize())
      });

      $('#issue_tracker_id').change(function() {
        $('#dialog-window').load('/kanban_issues/new.js', $('#issue-form').serialize())
      });

      $('#issue-form').submit(function() {
        $(this).ajaxSubmit({
          dataType: 'xml', // TODO: json format would prompt for a file download in the iframe
          success: function(responseText, statusText, xhr, $form) {
            $('.flash.notice').html(i18n.kanban_text_issue_created_reload_to_see).show();
            $('#dialog-window').dialog("close");
          },
          error: function(response) {
            $('#issue-form-errors').html(i18n.kanban_text_error_saving_issue).show();
          }
        });

        return false;
      });
    },

    // Take over the click events on the watch links used by redmine_recent_issues
    takeOverWatchLinks: function(jquerySelector) {
      $(jquerySelector).find('a.icon-fav-off').click(function() {
        this.watched_issue = true;
        $('#watch_and_cancel').html(i18n.kanban_text_watch_and_cancel_hint).show();
      });
    },

    registerUserSwitch: function() {
      $('#user_id').change(function() {
        $('form#user_switch').submit();
      });
    },

    initilize: function() {
      $(function($) {
        Kanban.initilize_after_dom_loaded();
      });
      $.noConflict();
    },

    initilize_after_dom_loaded: function() {
      this.registerAjaxIndicator();
    }
    
  };

  Kanban.initilize();

})(jQuery)
