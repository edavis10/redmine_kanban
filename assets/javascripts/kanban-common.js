(function($) {
  Kanban = {

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
