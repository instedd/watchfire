var onVolunteerIndex = function() {
  $(function(){
  	init_events();
  });

  function init_events() {
  	$('.link').click(function(){
  		var url = $(this).data('url');
  		window.location = url;
  	});
  	$('.avoid').click(function(event){
  		event.stopImmediatePropagation();
  	});
  }
};
