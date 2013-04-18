/*
@author : Brian J. Cardiff
@usage :
$.status.showInfo(msg);
$.status.showWarning(msg);
$.status.showError(msg, [kind]);
  * shows error only if no other error of same kind is already displayed.
*/
(function($) {
	
	$.extend({
		status: {
			showError: function(message, timeout) {
				this.show(message, 'flash_error', timeout);
			},
			showNotice: function(message, timeout) {
				this.show(message, 'flash_notice', timeout);
			},
			show: function(message, cssClass, timeout) {
				$('.flash').remove();
				var message = $('<div>').addClass('flash').addClass(cssClass).append($("<div>").text(message));
				$("body").prepend(message);
				this._display_flash(true, timeout);
			},
			
			// display flash div with animation if requested
			_display_flash: function(doAnimation, timeout){
				// for initial messages
				var message = $(".flash");
				var message_body = message.children("div");
				if (message.length == 0) return;
				
				// show message and set its position
				this._set_position(message);
				
				if (doAnimation) {
					// set message top to hide it
					message_body.css('top', -message.outerHeight() + 'px');
					
					// load timeout from data
					if (!timeout) {
						timeout = message.attr('data-hide-timeout');
					}

					// setup hide function if timeout is set
					var hideFunc = null;
					if (timeout) {
						hideFunc = function() {
							window.setTimeout(function() {
								message_body.animate({top : -message.outerHeight() + 'px'}, {duration: 1200});
							}, timeout);
						};
					}

					// display message with animation 200ms after page load
					window.setTimeout(function(){
						message_body.animate({top : 0}, {
							duration: 1200, 
							complete: hideFunc
						});
					}, 200);
				}
			},
			
			// sets the flash message on the appropriate position and shows it
			_set_position: function(dom) {
				var header = $(".app-header");
				var y = header.offset().top + header.height() + 17;
				var scrollY = $(window).scrollTop();
				dom.css('left', (($(document).width() - dom.outerWidth()) / 2) + 'px');
				if ( scrollY > y) {
					dom.css('top', '0px');
					dom.css('position', 'fixed');
					dom.css('z-index', 100);
				} else if ( scrollY < y) {
					dom.css('position', 'absolute');
					dom.css('top', y + 'px');
					dom.css('z-index', 0);
				}
				dom.show();
			}
		}
	});
		
	$(function(){ $.status._display_flash(true); });
	$(window).resize(function(){ $.status._display_flash(false); });
	$(window).scroll(function(){ $.status._display_flash(false); });

})(jQuery);
