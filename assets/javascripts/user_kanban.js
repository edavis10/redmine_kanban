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
        },
        "OK": function() {
          $(this).dialog("close");
        }
      }});


  $('#new-issue-dialog').click(function() {
    $('#dialog-window').
      html(''). // Gets cached
      load('/kanban_issues/new.js').
      dialog('open');
  });
});
