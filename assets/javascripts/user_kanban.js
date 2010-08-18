jQuery(function($) {
  $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
  $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

  $('#user_id').change(function() {
    $('form#user_switch').submit();
  });


  $('#dialog-window').
    dialog({
      autoOpen: false,
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
      html('<h2>Test</h2>').
      dialog('open');
  });
});
