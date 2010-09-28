jQuery(function($) {
  $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
  $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

  $('#user_id').change(function() {
    $('form#user_switch').submit();
  });


  $('#dialog-window').
    dialog({
      autoOpen: false,
      minWidth: 400,
      width: 800,
      buttons: {
        "Cancel": function() {
          $(this).dialog("close");
        }
      }});


  $('.new-issue-dialog').click(function() {
    $('#dialog-window').
      html(''). // Gets cached
      load('/kanban_issues/new.js').
      dialog('open');

    return false;
  });
});

function hideAttachmentsForm() {
  jQuery('#attachments_fields').closest('p').hide();
}

function registerNewIssueCallbacks() {
  jQuery('#issue_project_id').change(function() {
    jQuery('#dialog-window').load('/kanban_issues/new.js', jQuery('#issue-form').serialize())
  });

  jQuery('#issue-form').submit(function(event) {
    jQuery.ajaxQueue.post(jQuery('#issue-form').attr('action'), {
      data: jQuery('#issue-form').serialize(),
      success: function(response) {
        jQuery('.flash.warning').html(i18n.kanban_text_notice_reload).show();

        var another = confirm(i18n.kanban_text_notice_issue_created_and_continue);
        if (another) {
          jQuery('#issue-form')[0].reset();
        } else {
          jQuery('#dialog-window').dialog("close");
        }
      },
      error: function(response) {
        jQuery('#issue-form-errors').html(i18n.kanban_text_error_saving_issue).show();
      }
    });

    return false;
  });
}
