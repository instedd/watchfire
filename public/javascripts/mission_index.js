$(function(){
	init_events();
	show_by_status($('#combo_status').val());
});

function init_events() {
	$('.link').click(function(){
		var url = $(this).data('url');
		window.location = url;
	});
	
	$('#combo_status').change(function(event){
		var status = $(this).val();
		show_by_status(status);
	});
}

function show_by_status(status) {
	$('.mission').removeClass('hidden');
	
	if (status == 'active') {	
		$('.mission[data-status=finished]').addClass('hidden');
	} else if (status == 'finished') {
		$('.mission[data-status!=finished]').addClass('hidden');
	}
}