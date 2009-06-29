jQuery(function($) {
  $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
  $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

  attachSortables = function() {
    $("#incoming-issues").sortable({
      cancel: 'a',
      connectWith: ['#backlog-issues'],
      placeholder: 'drop-accepted',
      dropOnEmpty: true
    });

    $("#backlog-issues").sortable({
      cancel: 'a',
      connectWith: ['#incoming-issues','#selected-issues', '.active-issues', '.testing-issues'],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      }
    });

    $("#selected-issues").sortable({
      cancel: 'a',
      connectWith: ['#backlog-issues', '.active-issues', '.testing-issues'],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this));
        }
      }
    });

    $(".active-issues").sortable({
      cancel: 'a',
      connectWith: ['#backlog-issues', '#selected-issues', '.testing-issues'],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this));
        }
      }
    });

    $(".testing-issues").sortable({
      cancel: 'a',
      connectWith: ['#backlog-issues', '#selected-issues', '.active-issues'],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      },
      update: function (event, ui) {
        // Allow drag and drop inside the list
        if (ui.sender == null && event.target == this) {
          updatePanes(ui.item,ui.sender,$(this));
        }
      }
    });

  },

  attachSortables();

  updatePanes = function(issue, from, to) {
    var issue_id = issue.attr('id').split('_')[1];
    var to_pane = to.attr('id').split('-')[0];
    var to_order = to.sortable('serialize', {'key': 'to_issue[]'});

    if (from) {
      var from_pane = from.attr('id').split('-')[0];
      var from_order = from.sortable('serialize', {'key': 'from_issue[]'});
    } else {
      var from_pane = '';
      var from_order = [];
    }

    // Active pane needs to send which user was modified
    if (to_pane == 'active' || to_pane == 'testing') {
      var user_id = to.attr('id').split('-')[3];
    } else if (from_pane == 'active' || from_pane == 'testing'){
      var user_id = from.attr('id').split('-')[3];
    } else {
      var user_id = null;
    }


    $.ajax({
      type: "PUT",
      url: 'kanban.js',
      data: 'issue_id=' + issue_id + '&from=' + from_pane + '&to=' + to_pane + '&' + from_order + '&' + to_order + '&user_id=' + user_id,
      success: function(response) {
        var partials = $.secureEvalJSON(response);
        $(from).parent().html(partials.from);
        $(to).parent().html(partials.to);

        attachSortables();

      },
      error: function(response) {
        $("div.error").html("Error saving lists.  Please refresh the page and try again.").show();
      }
    });
  };
});

