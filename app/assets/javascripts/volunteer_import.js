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

		$('input[type=radio]').click(function(){
			filter_by($(this).val());
		});
		$('input[type=radio].default').attr('checked', 'checked');
		filter_by('all');
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

	function filter_by(selection) {
		$('.desc').hide();
		if (selection == 'all') {
			$('.volunteer').show();
		} else if (selection == 'new') {
			$('.volunteer').hide();
			$('.volunteer.new').not('.error').show();
			$('.desc.new').show();
		} else if (selection == 'existing') {
			$('.volunteer').hide();
			$('.volunteer.existing').not('.error').show();
			$('.desc.existing').show();
		} else if (selection == 'error') {
			$('.volunteer').hide();
			$('.volunteer.error').show();
			$('.desc.error').show();
		}
	}
};
