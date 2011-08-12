// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var map;
var mission_marker;
var geocoder;
var circle;

$(function(){
	init_map();
	init_events();
});

function init_map() {
	var myOptions = {
		zoom: 6,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	
	circle = new google.maps.Circle(); 

	var initialLocation = new google.maps.LatLng(35, -98);
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	map.setCenter(initialLocation);
	
	marker = new google.maps.Marker({
		map: map,
		draggable: true
  });
	
	var loc = new google.maps.LatLng(parseFloat($("#mission_lat").val()), parseFloat($("#mission_lng").val()));
	if(!isNaN(loc.lat()) && !isNaN(loc.lng())){		
		map.setCenter(loc);
		marker.setPosition(loc);
		setMapCircle(parseFloat($('#distance_value').html()));
	}

	geocoder = new google.maps.Geocoder();
	
	google.maps.event.addListener(map, 'click', changeMarker);
	google.maps.event.addListener(map, 'rightclick', changeMarker);
	google.maps.event.addListener(marker, 'dragend', changeMarker);
}
	
function changeMarker(event) {
	var location = event.latLng;
	$("#mission_lat").val(location.lat());
	$("#mission_lng").val(location.lng());
	map.setCenter(location);
	marker.setPosition(location);
	checkSubmit();
}

function geocodeLocation(location) {
	geocoder.geocode( { 'address': location }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var location = results[0].geometry.location;
			$("#mission_lat").val(location.lat());
			$("#mission_lng").val(location.lng());
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
	$('#mission_req_vols').change(function(){
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
		var value = $(this).val();
		if (value == 'all') $('tr.candidate').show();
		else {
			$('tr.candidate').hide();
			$('tr.candidate-confirmed').show();
		}
	});

	$('.coord').change(function(){
		var loc = new google.maps.LatLng(parseFloat($("#mission_lat").val()), parseFloat($("#mission_lng").val()));
		map.setCenter(loc);
		marker.setPosition(loc);
		checkSubmit();
	});
}

function setMapCircle(distance) {
	circle.setOptions({
		center: marker.getPosition(),
		map: map,
		radius: distance * 1619,
		fillOpacity: 0.3,
		clickable: false,
		fillColor: '#AAAA00',
		strokeWeight: 1
	});
}
