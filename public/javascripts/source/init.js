(function($){	
	$(function(){
		// initialize built-in components
		$(".ux-datepicker").datepicker();
		$("input[type='text']").addClass("ux-text")
		$("textarea").addClass("ux-text")
		$("input[readonly='readonly'], textarea[readonly='readonly']").addClass("readonly");
		$(".ux-dropdown select").addClass("styled") 			
	});
})(jQuery);