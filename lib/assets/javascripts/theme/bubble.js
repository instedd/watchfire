// Wrappers for jquery.bubblepopup for some extra functionality:
//     - open bubble by clicking on target
//     - define a selector to close popup
// 	   - provide a target content

(function($) {
	var defaults = {
		click: false,
		closeSelector: '.bubble_close',
		content: null
	};
	$.fn.extend({
		bubble: function(options) {
			options = $.extend({}, defaults, options || {});
			return $(this).map(function() {

				var _this = $(this);
				
				// If click then remove mouse events and define click event
				if (options.click) {
					options.manageMouseEvents = false;
					_this.click(function(e){
						_this.ShowBubblePopup();
						return false;
					});
				}
				
				// Content
				if (options.content) {
					options.innerHtml = options.content.html();
					options.content.remove();
				}
				
				// Close event
				$(options.closeSelector).live('click', function() {
					_this.HideBubblePopup();
				});
				
				_this.CreateBubblePopup(options);
			});
		}
	});
})(jQuery);