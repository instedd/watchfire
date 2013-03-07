function MapView(element) {
    var self = this;
    element = element || document.getElementById('map_canvas');

    var myOptions = {
        zoom: 10,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    var initialLocation = new google.maps.LatLng(37.520619, -122.342377);

    var icons = {
        eventDisabled: new google.maps.MarkerImage(
            '/images/icons/event_disabled.png',
            new google.maps.Size(30, 27),
            new google.maps.Point(0,0),
            new google.maps.Point(15, 13)
        ),
        eventEnabled: new google.maps.MarkerImage(
            '/images/icons/event.png',
            new google.maps.Size(30, 27),
            new google.maps.Point(0,0),
            new google.maps.Point(15, 13)
        ),
        volunteer: new google.maps.MarkerImage(
            '/images/icons/volunteer.png',
            new google.maps.Size(24, 24),
            new google.maps.Point(0,0),
            new google.maps.Point(12, 12)
        )
    };

    var circle = new google.maps.Circle({ clickable: false });
    var outerCircle = new google.maps.Circle({ clickable: false });

    var map = new google.maps.Map(element, myOptions);
    map.setCenter(initialLocation);

    var missionMarker = new google.maps.Marker({
        map: map,
        icon: icons.eventDisabled
    });

    var info_window = new google.maps.InfoWindow({
        content: document.getElementById("info_window_content")
    });
    var volunteerMarker = new google.maps.Marker({
        map: map,
        icon: icons.volunteer
    });

    init_map_events();

    var listener;

    function init_map_events() {
        missionMarker.setDraggable(true);
        listener = google.maps.event.addListener(map, 'rightclick', changeMarker); //removing right click also disables zoom, so I store it to be removed later
        google.maps.event.addListener(missionMarker, 'dragend', changeMarker);
        //google.maps.event.addListener(info_window, 'closeclick', on_info_window_closed);
    }

    function remove_map_events() {
        google.maps.event.removeListener(listener);
        google.maps.event.clearInstanceListeners(missionMarker);
        missionMarker.setDraggable(false);
    }

    // Exported methods
    self.onMarkerChanged = null;
    function changeMarker(event) {
        var location = event.latLng;
        map.setCenter(location);
        missionMarker.setPosition(location);
        if (self.onMarkerChanged) {
            self.onMarkerChanged(location);
        }
    }

    self.setMissionLocation = function(loc) {
        if (loc && !isNaN(loc.lat()) && !isNaN(loc.lng())) {
            map.setCenter(loc);
            missionMarker.setPosition(loc);
        }
    };

}

function MissionSkill(id, req_vols, skill_id) {
    var self = this;
    self.id = ko.observable(id);
    self.req_vols = ko.observable(req_vols);
    self.skill_id = ko.observable(skill_id);
    self._destroy = ko.observable(false);
}

function MissionViewModel() {
    var self = this;

    // DefaultSkill and ActiveSkills are defined by the view
    self.activeSkills = [DefaultSkill].concat(ActiveSkills || []);
    self.skillMap = {};
    $.each(self.activeSkills, function(index, skill) {
        self.skillMap[skill.id] = skill;
    });

    // mission hidden fields
    self.id = ko.observable();
    self.errors = ko.observable({});

    // mission editable fields
    self.name = ko.observable('');
    self.reason = ko.observable('');
    self.mission_skills = ko.observableArray();
    self.address = ko.observable('');
    self.latlng = ko.observable(null);
    self.status = ko.observable('created');

    // computed fields
    self.title = ko.computed(function() {
        var result = 'New Event';
        var req_skills = self.mission_skills();
        var name = self.name();
        var reason = self.reason();
        if (name) {
            result = name;
            req_skills = $.map($.grep(req_skills, function(req_skill) {
                return !req_skill._destroy();
            }), function(req_skill) {
                var req_vols = req_skill.req_vols();
                var skill = self.skillMap[req_skill.skill_id()] || DefaultSkill;
                return req_vols + ' ' + skill[req_vols == 1 ? 'name' : 'pluralized'];
            });
            result = result + ': ' + req_skills.join(', ');
            if (reason) {
                result += ' (' + reason + ')';
            }
        }
        return result;
    });

    // behavior methods
    self.addMissionSkill = function() {
        self.mission_skills.push(new MissionSkill(null, 1, null));
    };
    self.removeMissionSkill = function(skill) {
        if (skill.id) {
            skill._destroy(true);
        } else {
            self.mission_skills.remove(skill);
        }
    };
    self.findRecruitees = function() {
    };

    // initialization
    self.addMissionSkill();
    self.mapView = new MapView();

    self.latlng.subscribe(function(newValue) {
        self.mapView.setMissionLocation(newValue);
    });
    var _address = ko.observable();
    self.address = ko.computed({
        read: _address,
        write: function(newValue, stopGeocoding) {
            _address(newValue);
            if (!stopGeocoding) {
                geocodeAddress(newValue);
            }
        }
    });
    self.mapView.onMarkerChanged = function(location) {
        self.latlng(location);
        reverseGeocode(location);
    };

    // geocoding and reverse-geocoding
    var geocoder = new google.maps.Geocoder();
    function geocodeAddress(address) {
        geocoder.geocode({ 'address': address }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                var location = results[0].geometry.location;
                self.latlng(location);
            } else {
                alert("Location not found");
            }
        });
    }
    function reverseGeocode(location) {
        geocoder.geocode({ 'latLng': location }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                if (results[0]) {
                    // save address, but prevent further geocoding
                    self.address(results[0].formatted_address, true);
                }
            } else {
                alert("Reverse Geocoding failed");
                self.address('');
            }
        });
    }

    var submitData = ko.computed(function() {
        var location = self.latlng();
        var mission_skills = $.map(self.mission_skills(), function(ms) {
            var result = { req_vols: ms.req_vols(), skill_id: ms.skill_id() || '' };
            if (ms.id()) {
                result.id = ms.id();
                if (ms._destroy()) {
                    result._destroy = true;
                }
            }
            return result;
        });

        return {
            name: self.name(),
            address: self.address(),
            reason: self.reason(),
            lat: location && location.lat(),
            lng: location && location.lng(),
            mission_skills_attributes: mission_skills
        };
    }).extend({ throttle: 1 });

    self.submitData = submitData;

    self.dirty = ko.observable(false);
    self.saving = ko.observable(false);

    var submitTimeout = null;
    var pendingSubmit = null;
    var justMerged = false;
    submitData.subscribe(function(newValue) {
        if (justMerged) {
            justMerged = false;
            return;
        }
        delayedSubmit(newValue)
    });
    
    function delayedSubmit(data) {
        self.dirty(true);
        if (submitTimeout) {
            clearTimeout(submitTimeout);
        }
        submitTimeout = setTimeout(function() {
            submitIfNotPending(data);
        }, 500);
    }
    function submitIfNotPending(data) {
        if (pendingSubmit) {
            submitTimeout = setTimeout(function() {
                submitIfNotPending(submitData())
            }, 100);
            return;
        } else {
            submitTimeout = null;
        }
        // really submit
        self.saving(true);
        pendingSubmit = $.ajax({
            type: self.id() ? 'PUT' : 'POST',
            dataType: 'json',
            url: '/missions' + (self.id() ? '/' + self.id() : ''),
            data: {
                mission: data 
            }, 
            success: function(result) {
                console.log('SUCCESS!', result.errors);
                console.dir(result.mission);                

                // update local values
                self.id(result.mission.id);
                self.status(result.mission.status);
                mergeMissionSkills(result.mission.mission_skills);
                justMerged = true;
                setTimeout(function() { justMerged = false; }, 10);

                // process error messages
                self.errors(result.errors);

                pendingSubmit = null;
                if (!submitTimeout) {
                    self.dirty(false);
                }
                self.saving(false);
            },
            error: function(xhr, options, err) {
                alert(xhr.responseText);
                pendingSubmit = null;
                self.saving(false);
            }
        });
    }

    function mergeMissionSkills(to_merge) {
        var current = self.mission_skills();
        var i = 0, j = 0;
        while (i < current.length) {
            var cur_skill = current[i];
            if (cur_skill._destroy()) {
                // don't destroy if the item is in to_merge
                if (j < to_merge.length && to_merge[j].id == cur_skill.id()) {
                    // just skip it... it should be destroyed in the next submit
                    i++;
                    j++;
                } else {
                    current.splice(i, 1);
                    self.mission_skills.splice(i, 1);
                }
            } else {
                i++;
                if (j < to_merge.length) {
                    var new_skill = to_merge[j];
                    j++;
                    if (cur_skill.id() == null) {
                        cur_skill.id(new_skill.id);
                    } else if (cur_skill.id() != new_skill.id) {
                        cur_skill.id(new_skill.id);
                        cur_skill.req_vols(new_skill.req_vols);
                        cur_skill.skill_id(new_skill.skill_id);
                    }
                }
            }
        }
        while (j < to_merge.length) {
            var req_skill = to_merge[j];
            var new_skill = new MissionSkill(req_skill.id, 
                    req_skill.req_vols, req_skill.skill_id);
            self.mission_skills.push(new_skill);
            j++;
        }
    }
}

var model;
$(function() {
    model = new MissionViewModel();
    ko.applyBindings(model);
});

