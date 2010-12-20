jQuery(function($) {
  Kanban.registerUserSwitch();

  $('#dialog-window').
    dialog({
      position: [10,10],
      autoOpen: false,
      minWidth: 400,
      width: 800,
      close: function(event, ui) {
        if (Kanban.watched_issue) {
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
