jQuery(function($) {
  $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
  $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

  attachSortables = function() {
    // connectWith means that this item can be drug out of it's
    // sortable list and into an item in connectWith

    $("#incoming-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
      placeholder: 'drop-accepted',
      dropOnEmpty: true
    });

    $("#backlog-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this), '#quick-issues');
      }
    });

    $("#quick-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      }
    });

    $("#selected-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#backlog-issues',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
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
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
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
      connectWith: [
        '#backlog-issues',
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
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

    $(".finished-issues").sortable({
      cancel: 'a',
      connectWith: [
        '#selected-issues.allowed',
        '.active-issues.allowed',
        '.testing-issues.allowed',
        '.finished-issues.allowed'
      ],
      items: 'li.issue',
      placeholder: 'drop-accepted',
      dropOnEmpty: true,
      receive: function (event, ui) {
        updatePanes(ui.item,ui.sender,$(this));
      }
    });

  },

  attachSortables();

  // * issue
  // * from
  // * to
  // *  additional_pane - (optional) the id selector for an additional 3rd
  //    pane to update
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

    // Check for the optional additional pane
    if (arguments.length == 4) {
      var additional_pane = arguments[3];
      var additional_pane_name = arguments[3].split('-')[0].replace('#','');
    } else {
      var additional_pane = '';
    }

    // Active pane needs to send which user was modified
    if (to_pane == 'active' || to_pane == 'testing' || to_pane == 'finished') {
      var user_id = to.attr('id').split('-')[3];
    } else if (from_pane == 'active' || from_pane == 'testing' || to_pane == 'finished'){
      var user_id = from.attr('id').split('-')[3];
    } else {
      var user_id = null;
    }


    $.ajax({
      type: "PUT",
      url: 'kanban.js',
      data: 'issue_id=' + issue_id + '&from=' + from_pane + '&to=' + to_pane + '&' + from_order + '&' + to_order + '&user_id=' + user_id + '&additional_pane=' + additional_pane_name,
      success: function(response) {
        var partials = $.secureEvalJSON(response);
        $(from).parent().html(partials.from);
        $(to).parent().html(partials.to);

        if (additional_pane.length > 1) {
          $(additional_pane).parent().html(partials.additional_pane);
        }

        attachSortables();

      },
      error: function(response) {
        $("div.error").html("Error saving lists.  Please refresh the page and try again.").show();
      }
    });
  };
});

