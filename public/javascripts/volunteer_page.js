var volunteer_marker;
var map;
var volunteer_image;
var geocoder;

$(function(){
	$("#skills").superblyTagField({
		  allowNewTags: true,
		  showTagsNumber: 10,
		  preset: getHtmls($('#volSkills li')),
		  tags: getHtmls($('#allSkills li'))
	});

  init_map();
  
  $('.day-hour').click(function() {
    var elem = $(this);
    elem.toggleClass('gn gy');
    var input = elem.children();
    input.val(input.val() == '1' ? '0' : '1');
    checkHeaders();
  });

  $('.day, .hour').click(function() {
    var elem = $(this);
    elem.toggleClass('gn b');
    var active = elem.hasClass('gn');
    $('.'+elem.attr('id')).each(function() {
      var hour_elem = $(this);
      hour_elem.toggleClass('gn', active);
      hour_elem.toggleClass('gy', !active);
      hour_elem.children().val(active ? '1' : '0');
    });
    checkHeaders();
  });

  $('#square').click(function() {
    var elem = $(this);
    elem.toggleClass('gn b');
    var active = elem.hasClass('gn');
    $('.day, .hour, .day-hour').toggleClass('gn', active);
    $('.day-hour').toggleClass('gy', !active);
    $('.day, .hour').toggleClass('b', !active);
    $('.day-hour input').val(active ? '1' : '0');
  });

  checkHeaders();

  $('#cancelbtn').click(function(){
    history.back();
  });

});

function checkHeaders(){
  var available;

  for(i = 0; i < 7; i++) {
    available = true;
    $('.day'+i).each(function() {
      available = $(this).children().val() != '0';
      return available;
    });
    $("#day"+i).toggleClass('gn', available);
    $("#day"+i).toggleClass('b', !available);
  }

  for(i = 0; i < 24; i++) {
    available = true;
    $('.hour'+i).each(function() {
      available = $(this).children().val() != '0';
      return available;
    });
    $("#hour"+i).toggleClass('gn', available);
    $("#hour"+i).toggleClass('b', !available);
  }

  available = $(".day.gn").length == 7 && $(".hour").length == 24
  $("#square").toggleClass('gn', available);
  $("#square").toggleClass('b', !available);  
}

function getHtmls(obj) {
	var ret = [];
	obj.each(function(){ret.push($(this).html());});
	return ret;
}

function init_map(){

	var myOptions = {
		zoom: 10,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
		
	volunteer_image = new google.maps.MarkerImage('/images/icons/volunteer.png',
		new google.maps.Size(24, 24),
		new google.maps.Point(0,0),
		new google.maps.Point(12, 12));

	var initialLocation = new google.maps.LatLng(37.520619, -122.342377);
	map = new google.maps.Map(document.getElementById("map_canvas_volunteer"), myOptions);
	map.setCenter(initialLocation);

	volunteer_marker = new google.maps.Marker({
		map: map,
		icon: volunteer_image
	});

	var loc = new google.maps.LatLng(parseFloat($("#volunteer_lat").val()), parseFloat($("#volunteer_lng").val()));
	if(!isNaN(loc.lat()) && !isNaN(loc.lng())){		
		map.setCenter(loc);
		volunteer_marker.setPosition(loc);
	}

  geocoder = new google.maps.Geocoder();

	volunteer_marker.setDraggable(true);
	google.maps.event.addListener(map, 'rightclick', changeMarker);
	google.maps.event.addListener(volunteer_marker, 'dragend', changeMarker);

	$("#volunteer_address").keypress(function(event){
		if (event.keyCode == 13) {
      var loc = $(this).val();
			geocodeLocation(loc);
			return false;
        } else {
          return true;
        }
	});
}

function changeMarker(event) {
	var location = event.latLng;
	$("#volunteer_lat").val(location.lat().toFixed(4));
	$("#volunteer_lng").val(location.lng().toFixed(4));
	map.setCenter(location);
	volunteer_marker.setPosition(location);
	reverseGeocode(location);
}

function geocodeLocation(location) {
	geocoder.geocode( { 'address': location }, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			var location = results[0].geometry.location;
			$("#volunteer_lat").val(location.lat().toFixed(4));
			$("#volunteer_lng").val(location.lng().toFixed(4));
			map.setCenter(location);
			volunteer_marker.setPosition(location);
		} else {
			alert("Location not found");
    	}
	});
}

function reverseGeocode(loc) {
	geocoder.geocode({'latLng': loc}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			if (results[0]) {
				$("#volunteer_address").val(results[0].formatted_address);
			}
		} else {
			alert("Reverse Geocoding failed");
			$("#volunteer_address").val('');
		}
	});
}

