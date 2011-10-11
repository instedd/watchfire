// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(function(){
	$('#invite_bubble_trigger').bubble({
		position : 'top',
		content: $("#invite_bubble_content"),
		closeSelector: '#invite_bubble_close',
		themeName: 	'bubble',
		innerHtmlStyle: {
			color:'#000000',
			'background-color': 'white'
		},
		themePath: 'http://theme.instedd.org/theme/images/',
		click: true
	});
});