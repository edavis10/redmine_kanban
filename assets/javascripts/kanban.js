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
        dropOnEmpty: true
    });

});

