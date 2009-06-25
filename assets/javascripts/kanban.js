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
            connectWith: ['#incoming-issues','#selected-issues'],
            items: 'li.issue',
            placeholder: 'drop-accepted',
            dropOnEmpty: true,
            update: function (event, ui) {
              if (ui.sender) {
                updatePanes(ui.item,ui.sender,$(this));
              }
            }
        });

        $("#selected-issues").sortable({
            cancel: 'a',
            connectWith: ['#backlog-issues'],
            items: 'li.issue',
            placeholder: 'drop-accepted',
            dropOnEmpty: true,
            update: function (event, ui) {
              if (ui.sender) {
                updatePanes(ui.item,ui.sender,$(this));
              }
            }
        });

    },

    attachSortables();

    updatePanes = function(issue, from, to) {
        var issue_id = issue.attr('id').split('_')[1];
        var from_pane = from.attr('id').split('-')[0];
        var to_pane = to.attr('id').split('-')[0];

        var from_order = from.sortable('serialize', {'key': 'from_issue[]'});
        var to_order = to.sortable('serialize', {'key': 'to_issue[]'});

        $.ajax({
            type: "PUT",
            url: 'kanban.js',
            data: 'issue_id=' + issue_id + '&from=' + from_pane + '&to=' + to_pane + '&' + from_order + '&' + to_order,
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

