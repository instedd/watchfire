// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var map;
var mission_marker;
var geocoder;

$(function(){
	init_map();
});

function init_map() {
	var myOptions = {
		zoom: 6,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	
	var initialLocation = new google.maps.LatLng(60, 105);
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	map.setCenter(initialLocation);
	
	marker = new google.maps.Marker({
		map: map,
    });

	geocoder = new google.maps.Geocoder();
	
	google.maps.event.addListener(map, 'click', function(event) {
		var location = event.latLng;
		$("#mission_lat").val(location.lat());
		$("#mission_lng").val(location.lng());
		map.setCenter(location);
		marker.setPosition(location);
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
}

function geocodeLocation(location) {
	geocoder.geocode( { 'address': location }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var location = results[0].geometry.location;
			$("#mission_lat").val(location.lat());
			$("#mission_lat").val(location.lng());
			map.setCenter(location);
			marker.setPosition(location);
		} else {
			alert("Location not found");
			//$feedback = $("#feedback");
			//$feedback.show();
			//$feedback.html("Location not found");
    	}
	});
}
