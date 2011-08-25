var map;
var mission_marker;
var geocoder;
var circle;
var refreshing;
var beating;
var alternance;
var info_window;
var volunteer_marker;

$(function(){
	init_map();
	init_events();
	check_running();
});

function init_map() {
	var myOptions = {
		zoom: 10,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	
	circle = new google.maps.Circle(); 

	var initialLocation = new google.maps.LatLng(37.520619, -122.342377);
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	map.setCenter(initialLocation);
	
	marker = new google.maps.Marker({
		map: map,
	});
	
	var loc = new google.maps.LatLng(parseFloat($("#mission_lat").val()), parseFloat($("#mission_lng").val()));
	if(!isNaN(loc.lat()) && !isNaN(loc.lng())){		
		map.setCenter(loc);
		marker.setPosition(loc);
		setMapCircle(parseFloat($('#distance_value').html()));
	}

	geocoder = new google.maps.Geocoder();
	
	info_window = new google.maps.InfoWindow({
	    content: document.getElementById("info_window_content")
	});
	volunteer_marker = new google.maps.Marker({
		map: map
	});

	init_map_events();
}

function init_map_events() {
	marker.setDraggable(true);
	google.maps.event.addListener(map, 'click', changeMarker);
	google.maps.event.addListener(map, 'rightclick', changeMarker);
	google.maps.event.addListener(marker, 'dragend', changeMarker);
	google.maps.event.addListener(info_window, 'closeclick', on_info_window_closed)
}

function remove_map_events() {
	google.maps.event.clearInstanceListeners(map);
	google.maps.event.clearInstanceListeners(marker);
	marker.setDraggable(false);
}
	
function changeMarker(event) {
	var location = event.latLng;
	$("#mission_lat").val(location.lat().toFixed(4));
	$("#mission_lng").val(location.lng().toFixed(4));
	map.setCenter(location);
	marker.setPosition(location);
	reverseGeocode(location);
}

function geocodeLocation(location) {
	geocoder.geocode( { 'address': location }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var location = results[0].geometry.location;
			$("#mission_lat").val(location.lat().toFixed(4));
			$("#mission_lng").val(location.lng().toFixed(4));
			map.setCenter(location);
			marker.setPosition(location);
			checkSubmit();
		} else {
			alert("Location not found");
			//$feedback = $("#feedback");
			//$feedback.show();
			//$feedback.html("Location not found");
    	}
	});
}

function checkSubmit() {
	if(parseInt($('#mission_req_vols').val()) > 0 && $("#mission_lat").val().length > 0 && $("#mission_lng").val().length > 0) {
		$('#mission_form').submit();
	}
}

function init_events() {
	$('#mission_req_vols, #mission_reason').change(function(){
		checkSubmit();
	});

	$("#mission_address").keypress(function(event){
		if (event.keyCode == 13) {
      var loc = $(this).val();
			geocodeLocation(loc);
			return false;
        } else {
          //$("#feedback").hide();
          return true;
        }
	});

	$('input:radio[name=filter_btn]').change(function(){
		checkFilter($(this).val());
	});

	$('.coord').change(function(){
		var loc = new google.maps.LatLng(parseFloat($("#mission_lat").val()), parseFloat($("#mission_lng").val()));
		if(!isNaN(loc.lat()) && !isNaN(loc.lng())){		
			map.setCenter(loc);
			marker.setPosition(loc);
			reverseGeocode(loc);
		}	
	});
	
	$('.candidate').click(function(){
		open_volunteer_info_window($(this));
	});
}

function checkFilter(value) {
		if (value == 'all') $('tr.candidate').show();
		else {
			$('tr.candidate').hide();
			$('tr.candidate-confirmed').show();
		}
}

function setMapCircle(distance, avoidFit) {
	circle.setOptions({
		center: marker.getPosition(),
		map: map,
		radius: distance * 1609,
		fillOpacity: 0,
		clickable: false,
		fillColor: '#AAAA00',
		strokeWeight: circle.strokeWeight != null ? circle.strokeWeight : 3,
		strokeColor: circle.strokeColor != null ? circle.strokeColor : '#666666'
	});
	if (!avoidFit) map.fitBounds(circle.getBounds());
}

function reverseGeocode(loc) {
	geocoder.geocode({'latLng': loc}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			if (results[0]) {
				$("#mission_address").val(results[0].formatted_address);
			}
		} else {
			alert("Reverse Geocoding failed");
			$("#mission_address").val('');
		}
		checkSubmit();
	});
}

function start_refreshing() {
	refreshing = true;
	refresh();
}

function stop_refreshing()  {
	refreshing = false;
}

function refresh() {
	if (!refreshing) return;
	
	$.getScript($("#volunteers").attr('data-refresh-url'), function(data, textStatus){
		setTimeout(refresh, 5000);  
	});
}

function refresh_disable_inputs() {
		start_refreshing();
		$('.mission_form_input').attr('disabled','disabled');
		remove_map_events();
		make_circle_beat();
}

function stop_refresh_enable_inputs() {
	stop_refreshing();
	$('#mission_req_vols, #mission_reason').removeAttr('disabled');
	stop_circle_beat();
}

function check_running() {
	var status = $('#status_field').val();
	if(status == 'running') {
		refresh_disable_inputs();
	} else if(status == 'paused' || status == 'finished') {
		$('.strict_mission_form_input').attr('disabled','disabled');
		remove_map_events();
	}
}

function make_circle_beat() {
	beating = true;
	alternance = 0;
	beat();
}

function stop_circle_beat()  {
	beating = false;
	circle.setOptions({strokeColor: '#666666', strokeWeight: 3});
}

function beat() {
	if (!beating) return;
	alternance = (alternance + 1) % 2;
	circle.setOptions({strokeWeight: (2 + 2 * alternance), strokeColor: '#FF0000'});
	setTimeout(beat, 250);
}

function open_volunteer_info_window(volunteer) {
	var url = volunteer.attr('data-url');
	var lat = volunteer.attr('data-lat');
	var lng = volunteer.attr('data-lng');
	var location = new google.maps.LatLng(lat, lng);
	
	$.get(url, function(data) {
		$('#info_window_content').html(data);
		volunteer_marker.setPosition(location);
		volunteer_marker.setVisible(true);
		info_window.open(map, volunteer_marker);
		volunteer.addClass('hilighted');
	});
}

function on_info_window_closed(event) {
	$('.candidate.hilighted').removeClass('hilighted');
	volunteer_marker.setVisible(false);
}