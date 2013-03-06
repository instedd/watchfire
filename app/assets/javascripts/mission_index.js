$(function(){
	init_events();
    var status = $.cookie('mission_combo_status');
    if (status !== undefined) {
        $('#combo_status').val(status);
        show_by_status(status);
    } else {
        show_by_status($('#combo_status').val());
    }
});

function init_events() {
	$('.link').click(function(){
		var url = $(this).data('url');
		window.location = url;
	});

	$('#combo_status').change(function(event){
		var status = $(this).val();
        $.removeCookie('mission_combo_status');
        $.cookie('mission_combo_status', status);
		show_by_status(status);
	});
}

function show_by_status(status) {
	$('.mission').removeClass('hidden');

	if (status == 'active') {
		$('.mission[data-status!=running]').addClass('hidden');
	} else if (status == 'finished') {
		$('.mission[data-status!=finished]').addClass('hidden');
	}
}
