var onVolunteerImport = function() {
	$(function(){
		init_events();
		show_by_status($('#combo_status').val());

		$('.error_trigger').each(function(){
			var trigger = $(this);
			trigger.bubble({
				position : 'top',
				themeName: 'bubble',
				themePath: 'http://theme.instedd.org/theme/images/',
				innerHtmlStyle: {
					color:'#000000',
					'background-color': 'white'
				},
				content: trigger.siblings('.error_content')
			});
		});
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
};
