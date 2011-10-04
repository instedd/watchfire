$(function(){
	init_events();
	show_by_status($('#combo_status').val());
});

function init_events() {	
	$('#combo_status').change(function(event){
		var status = $(this).val();
		show_by_status(status);
	});
}

function show_by_status(status) {
	$('.volunteer').removeClass('hidden');
	
	if (status == 'valid') {	
		$('.conflict').addClass('hidden');
	} else if (status == 'conflict') {
		$('.valid').addClass('hidden');
	}
}