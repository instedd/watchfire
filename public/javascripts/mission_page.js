var map;
var mission_marker;
var geocoder;

var circle;
var outerCircle;
var innerCircles = new Array();

var refreshing;
var beating;
var alternance;
var info_window;
var volunteer_marker;
var listener;
var event_image;
var event_disabled_image;
var volunteer_image;
var circleHasMap;

$(function(){
  circleHasMap = false;
	init_map();
	init_events();
	check_running();
});

function init_map() {
	var myOptions = {
		zoom: 10,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	
	event_disabled_image = new google.maps.MarkerImage('/images/icons/event_disabled.png',
		new google.maps.Size(30, 27),
		new google.maps.Point(0,0),
		new google.maps.Point(15, 13));
		
	event_image = new google.maps.MarkerImage('/images/icons/event.png',
		new google.maps.Size(30, 27),
		new google.maps.Point(0,0),
		new google.maps.Point(15, 13));
		
	volunteer_image = new google.maps.MarkerImage('/images/icons/volunteer.png',
		new google.maps.Size(24, 24),
		new google.maps.Point(0,0),
		new google.maps.Point(12, 12));
	
	circle = new google.maps.Circle();
  outerCircle = new google.maps.Circle();
  
  for(i = 0; i < 4; i++) {
    innerCircles.push(new google.maps.Circle());
  }

	var initialLocation = new google.maps.LatLng(37.520619, -122.342377);
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	map.setCenter(initialLocation);
	
	mission_marker = new google.maps.Marker({
		map: map,
		icon: event_disabled_image
	});
	
	var loc = new google.maps.LatLng(parseFloat($("#mission_lat").val()), parseFloat($("#mission_lng").val()));
	if(!isNaN(loc.lat()) && !isNaN(loc.lng())){		
		map.setCenter(loc);
		mission_marker.setPosition(loc);
		setMapCircle(parseFloat($('#distance_value').html()));
	}

	geocoder = new google.maps.Geocoder();
	
	info_window = new google.maps.InfoWindow({
	    content: document.getElementById("info_window_content")
	});
	volunteer_marker = new google.maps.Marker({
		map: map,
		icon: volunteer_image
	});

	init_map_events();
}

function init_map_events() {
	mission_marker.setDraggable(true);
	listener = google.maps.event.addListener(map, 'rightclick', changeMarker); //removing right click also disables zoom, so I store it to be removed later
	google.maps.event.addListener(mission_marker, 'dragend', changeMarker);
	google.maps.event.addListener(info_window, 'closeclick', on_info_window_closed);
}

function remove_map_events() {
	google.maps.event.removeListener(listener);
	google.maps.event.clearInstanceListeners(mission_marker);
	mission_marker.setDraggable(false);
}
	
function changeMarker(event) {
	var location = event.latLng;
	$("#mission_lat").val(location.lat().toFixed(4));
	$("#mission_lng").val(location.lng().toFixed(4));
	map.setCenter(location);
	mission_marker.setPosition(location);
	reverseGeocode(location);
}

function geocodeLocation(location) {
	geocoder.geocode( { 'address': location }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var location = results[0].geometry.location;
			$("#mission_lat").val(location.lat().toFixed(4));
			$("#mission_lng").val(location.lng().toFixed(4));
			map.setCenter(location);
			mission_marker.setPosition(location);
			checkSubmit();
		} else {
			alert("Location not found");
    	}
	});
}

function checkSubmit() {
	if(parseInt($('#mission_req_vols').val()) > 0 && $("#mission_lat").val().length > 0 && $("#mission_lng").val().length > 0) {
		$('#mission_form').submit();
	}
}

function init_events() {
	$('#mission_req_vols, #mission_reason, #mission_skill_id').change(function(){
		checkSubmit();
	});

	$("#mission_address").keypress(function(event){
		if (event.keyCode == 13) {
      var loc = $(this).val();
			geocodeLocation(loc);
			return false;
        } else {
          return true;
        }
	});
	
  init_candidate_events();
}

function init_candidate_events() {
	$('.candidate td').click(function(){
		open_volunteer_info_window($(this).parents('.candidate'));
	});
	
	$('.candidate .avoid').click(function(event){
		event.stopImmediatePropagation();
	});
}

function setMapCircle(distance, avoidFit) {
  if (circleHasMap) {
    outerCircle.setOptions({
		  center: mission_marker.getPosition(),
		  radius: distance * 1609,
		  clickable: false,
		  strokeWeight: 4,
		  strokeColor: '#FFFFFF',
		  fillOpacity: outerCircle.fillOpacity != null ? outerCircle.fillOpacity : 0.5,
		  fillColor: '#000000'
    });

	  circle.setOptions({
		  center: mission_marker.getPosition(),
		  radius: distance * 1609,
		  strokeWeight: 2,
		  strokeColor: circle.strokeColor != null ? circle.strokeColor : '#999999',
      fillOpacity: 0.0
	  });
  } else {
    outerCircle.setOptions({
		  center: mission_marker.getPosition(),
		  map: map,
		  radius: distance * 1609,
		  clickable: false,
		  strokeWeight: 4,
		  strokeColor: '#FFFFFF',
		  fillOpacity: outerCircle.fillOpacity != null ? outerCircle.fillOpacity : 0.5,
		  fillColor: '#000000'
    });

	  circle.setOptions({
		  center: mission_marker.getPosition(),
		  map: map,
		  radius: distance * 1609,
		  strokeWeight: 2,
		  strokeColor: circle.strokeColor != null ? circle.strokeColor : '#999999',
      fillOpacity: 0.0
	  });
    
    circleHasMap = true;
  }
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
	
	$.getScript($('#refresh_url').val(), function(data, textStatus){
		setTimeout(refresh, 5000);  
	});
}

function refresh_disable_inputs() {
	start_refreshing();
	$('#left_panel').addClass('grey');
	remove_map_events();
	make_circle_beat();
	mission_marker.setIcon(event_image);
}

function stop_refresh_enable_inputs() {
	stop_refreshing();
	$('#left_panel').removeClass('grey');
	stop_circle_beat();
	mission_marker.setIcon(event_disabled_image);
}

function check_running() {
	var status = $('#status_field').val();
	if (status == 'running') {
		refresh_disable_inputs();
	} else if (status == 'paused' || status == 'finished') {
		remove_map_events();
		if (status == 'finished') {
			$('#left_panel').addClass('grey');
		}
	}
}

function make_circle_beat() {
  circle.setOptions({strokeColor: '#FF6600'});
  outerCircle.setOptions({fillOpacity: 0.1});
	beating = true;
	alternance = 0;

  for(i = 0; i < innerCircles.length; i++) {
    innerCircles[i].setOptions({
		  center: mission_marker.getPosition(),
		  map: map,
		  radius: i * circle.getRadius() / innerCircles.length,
		  clickable: false,
		  strokeWeight: 0,
		  fillOpacity: 0.1,
		  fillColor: '#000000'
    });
  }
	beat();
}

function stop_circle_beat()  {
	beating = false;
	circle.setOptions({strokeColor: '#999999'});
  outerCircle.setOptions({fillOpacity: 0.5});
  for(i = 0; i < innerCircles.length; i++) {
    innerCircles[i].setOptions({
		  fillOpacity: 0,
    });
  }  
}

function beat() {
	if (!beating) return;
	alternance = (alternance + 3) % 100;
  for(i = 0; i < innerCircles.length; i++) {
    innerCircles[i].setOptions({
		  radius: circle.getRadius() * (i + alternance / 100) / innerCircles.length,
    });
  }
  innerCircles[innerCircles.length-1].setOptions({ fillOpacity: 0.1 * (1 - (alternance / 100))});
	setTimeout(beat, 50);
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
	});
}

function on_info_window_closed() {
	volunteer_marker.setVisible(false);
}

function close_info_window() {
	info_window.close();
	volunteer_marker.setVisible(false);
}
