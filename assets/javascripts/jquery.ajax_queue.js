// AjaxQueue - by Pat Nakajima
(function($) {
  var startNextRequest = function() {
    if ($.ajaxQueue.currentRequest) { return; }
    if (request = $.ajaxQueue.queue.shift()) {
      $.ajaxQueue.currentRequest = request;
      request.perform();
    }
  }
  
  var Request = function(url, type, options) {
    this.opts = options || { };
    this.opts.url = url;
    this.opts.type = type;
    var oldComplete = this.opts.complete || function() { }
    this.opts.complete = function(response) {
      oldComplete(response);
      $.ajaxQueue.currentRequest = null;
      startNextRequest();
    };
  }
  
  Request.prototype.perform = function() {
    $.ajax(this.opts);
  }
  
  var addRequest = function(url, type, options) {
    var request = new Request(url, type, options);
    $.ajaxQueue.queue.push(request);
    startNextRequest();
  }
  
  $.ajaxQueue = {
    queue: [],
    
    currentRequest: null,
    
    reset: function() {
      $.ajaxQueue.queue = [];
      $.ajaxQueue.currentRequest = null;
    },
    
    post: function(url, options) {
      addRequest(url, 'POST', options);
    },
    
    get: function(url, options) {
      addRequest(url, 'GET', options);
    },
    
    put: function(url, options) {
      addRequest(url, 'PUT', options);
    },
    
    del: function(url, options) {
      addRequest(url, 'DELETE', options);
    }
  }
})(jQuery)