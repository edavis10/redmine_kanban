jQuery(function($) {
    $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
    $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });


    $("#incoming-issues").sortable({
        cancel: 'a',
        connectWith: ['#backlog-issues'],
        placeholder: 'drop-accepted',
        dropOnEmpty: true
    });

    $("#backlog-issues").sortable({
        cancel: 'a',
        connectWith: ['#incoming-issues'],
        items: 'li.issue',
        placeholder: 'drop-accepted',
        dropOnEmpty: true,
        update: function (event, ui) {
            updatePanes(ui.item,ui.sender,$(this));
        }
    });

    updatePanes = function(issue, from, to) {
        var issue_id = issue.attr('id').split('_')[1];
        var from_pane = from.attr('id').split('-')[0];
        var to_pane = to.attr('id').split('-')[0];

        $.ajax({
            type: "PUT",
            url: 'kanban.js',
            data: 'issue_id=' + issue_id + '&from=' + from_pane + '&to=' + to_pane,
            success: function(response) {
                var partials = $.secureEvalJSON(response);
                $(from).parent().html(partials.from);
                $(to).parent().html(partials.to);
                // TODO: reattach sortables
            }
        });

    };

});

