(function($) {
  Kanban = {

    registerAjaxIndicator: function() {
      $("#ajax-indicator").ajaxStart(function(){ $(this).show();  });
      $("#ajax-indicator").ajaxStop(function(){ $(this).hide();  });

    },

    initilize: function() {
      $(function($) {
        Kanban.initilize_after_dom_loaded();
      });
      $.noConflict();
    },

    initilize_after_dom_loaded: function() {
      this.registerAjaxIndicator();
    }
    
  };

  Kanban.initilize();

})(jQuery)
