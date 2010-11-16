var watched_issue = false;

jQuery(function($) {
  $('#user_id').change(function() {
    $('form#user_switch').submit();
  });


  $('#dialog-window').
    dialog({
      position: [10,10],
      autoOpen: false,
      minWidth: 400,
      width: 800,
      close: function(event, ui) {
        if (watched_issue) {
          $('.flash.notice').html(i18n.kanban_text_issue_watched_reload_to_see).show();
        }
      },
      buttons: {
        "Cancel": function() {
          $(this).dialog("close");
        }
      }});


  $('.new-issue-dialog').click(function() {
    $('#dialog-window').
      html(''). // Gets cached
      load('/kanban_issues/new.js').
      dialog("option", "width", $('#content').width()). // Set width to the content width
      dialog('open');

    return false;
  });
});

function hideAttachmentsForm() {
  jQuery('#attachments_fields').closest('p').hide();
}

function takeOverWatchLinks(jquerySelector) {
  jQuery(jquerySelector).find('a.icon-fav-off').click(function() {
    watched_issue = true;
    jQuery('#watch_and_cancel').html(i18n.kanban_text_watch_and_cancel_hint).show();
  });
}
