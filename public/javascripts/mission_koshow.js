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

function CandidateView(data) {
    var self = this;
    self._data = data;
    for (var prop in data) {
        self[prop] = data[prop];
    }

    self.isPending = data.status == 'pending';
    function buildNumbers(collection, spanClass) {
        var result = [];
        for (var i = 0; i < collection.length; i++) {
            result.push($('<span>').text(collection[i].address).
                    addClass(spanClass).wrap('<p>').parent().html());
        }
        return result.join('<br>');
    }
    self.volunteer.sms_numbers = buildNumbers(data.volunteer.sms_channels, 'mobile');
    self.volunteer.voice_numbers = buildNumbers(data.volunteer.voice_channels, 'phone');
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
    self.latlng = ko.observable(null);
    self.status = ko.observable('created');
    self.farthest = ko.observable(0);
    self.confirmed_count = ko.observable(0);
    self.use_custom_text = ko.observable(false);
    self.custom_text = ko.observable(null);

    self.candidates = ko.observableArray();
    self.confirmed_candidates = ko.observableArray();
    self.pending_candidates = ko.observableArray();
    self.unresponsive_candidates = ko.observableArray();
    self.denied_candidates = ko.observableArray();

    // address is special due to geocoding: we don't want to geocode if the
    // address comes from reverse geocoding or the server
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
    self.visibleSkills = ko.computed(function() {
        var req_skills = self.mission_skills();
        var result = 0;
        for (var i = 0; i < req_skills.length; i++) {
            if (!req_skills[i]._destroy()) {
                result++;
            }
        }
        return result;
    });
    self.distanceLegend = ko.computed(function() {
        if (self.status() == 'running') {
            return 'Calling volunteers up to';
        } else {
            return 'Will call volunteers up to';
        }
    });
    self.isRunning = ko.computed(function() {
        return self.status() == 'running';
    });
    self.isRunningOrFinished = ko.computed(function() {
        return self.status() == 'running' || self.status() == 'finished';
    });
    self.isFinished = ko.computed(function() {
        return self.status() == 'finished';
    });
    self.buttonText = ko.computed(function() {
        var status = self.status();
        if (status == 'created') {
            return 'Start recruiting';
        } else if (status == 'running') {
            return 'Pause recruiting';
        } else if (status == 'paused') {
            return 'Resume recruiting';
        } else {
            return 'Open event';
        }
    });
    self.buttonCss = ko.computed(function() {
        var status = self.status();
        if (status == 'created') {
            return 'orange' + (self.id() ? '' : ' disabled');
        } else if (status == 'running' || status == 'paused') {
            return 'white';
        } else {
            return 'orange';
        }
    });
    self.confirmedText = ko.computed(function() {
        if (self.id() == null) {
            return 'No recruitees<br>required yet';
        } else {
            var cc = self.confirmed_count();
            return (cc > 0 ? cc : 'No volunteers') + '<br>confirmed';
        }
    });
    self.total_req_vols = ko.computed(function() {
        var req_skills = self.mission_skills();
        var result = 0;
        for (var i = 0; i < req_skills.length; i++) {
            result += req_skills[i].req_vols();
        }
        return result;
    });
    self.neededText = ko.computed(function() {
        if (self.id() != null) {
            return self.total_req_vols() + '<br>needed';
        }
    });
    self.progressStyle = ko.computed(function() {
        var progress = Math.min((self.confirmed_count() / 
                self.total_req_vols() * 100), 100);
        return { 'width': progress + '%' };
    });
    self.reason_with_default = ko.computed(function() {
        var reason = self.reason();
        if (reason) {
            return reason;
        } else {
            return 'a single house fire';
        }
    });
    self.address_with_default = ko.computed(function() {
        var address = self.address();
        if (address) {
            return address;
        } else {
            return '1710 Trousdale, Burlingame';
        }
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
    self.startStop = function() {
        // FIXME
    };

    // initialization
    self.addMissionSkill();
    self.mapView = new MapView();

    self.latlng.subscribe(function(newValue) {
        self.mapView.setMissionLocation(newValue);
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

    // save & load code
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

    var merging = false;
    // this function is to stop data submits if we have to change the model
    // programmatically, which would in turn recompute submitData and enqueue a
    // new submit
    function startForcedUpdate() {
        merging = true;
        // reset flag in a timeout because submitData is throttled
        setTimeout(function() { merging = false; }, 20);
    }
    submitData.subscribe(function(newValue) {
        // enqueue a data submit unless we're in the middle of a forced model
        // change
        if (merging) {
            return;
        }
        delayedSubmit(newValue);
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
        console.log('Submitting data');
        self.saving(true);
        pendingSubmit = $.ajax({
            type: self.id() ? 'PUT' : 'POST',
            dataType: 'json',
            url: '/missions' + (self.id() ? '/' + self.id() : ''),
            data: {
                mission: data 
            }, 
            success: function(result) {
                console.log('Submit successful');

                // update local values
                startForcedUpdate();
                self.id(result.mission.id);
                self.status(result.mission.status);
                mergeMissionSkills(result.mission.mission_skills);
                loadCandidates(result.mission.candidates);

                // process error messages
                self.errors(result.errors);

                pendingSubmit = null;
                if (!submitTimeout) {
                    self.dirty(false);
                }
                self.saving(false);
            },
            error: function(xhr, options, err) {
                console.error('Mission submit error', err);
                pendingSubmit = null;
                self.saving(false);
            }
        });
    }

    function mergeMissionSkills(to_merge) {
        // for each to_merge skill:
        // - exists in current
        //   - current it destroyed -> skip, should be deleted next submit
        //   - current is not destroyed -> should update, but won't since that 
        //      would overwrite some user changes
        // - doesn't exists in current 
        //   - there is some current with null id -> match up and save the id 
        //      to current
        //   - no current with null id -> add to current with _destroy: true 
        //      so it gets deleted in the next submit
        //
        // for the remaining current skills:
        // - if it has null id -> leave it there so next submit it gets added
        // - it has a non null id -> delete it from the collection, the skill 
        //      doesn't actually exist
        //

        function buildArrayIndex(ary) {
            var result = {};
            for (var i = 0; i < ary.length; i++) {
                var id = ary[i].id();
                if (id != null) {
                    result[id] = i;
                }
            }
            return result;
        }

        var current = self.mission_skills();
        var currentIndex = buildArrayIndex(current);
        var skillsNotInCurrent = [];

        for (var i = 0; i < to_merge.length; i++) {
            var new_skill = to_merge[i];
            if (new_skill.id in currentIndex) {
                delete currentIndex[new_skill.id];
            } else {
                skillsNotInCurrent.push(new_skill);
            }
        }

        i = 0;
        while (i < current.length) {
            var cur_skill = current[i];
            if (cur_skill.id() == null) {
                // this is an added skill
                // if possible match it up with skillsNotInCurrent, otherwise
                // just leave it there so it gets added on next submit
                var new_skill = skillsNotInCurrent.shift();
                if (new_skill) {
                    cur_skill.id(new_skill.id);
                }
                i++;
            } else if (cur_skill.id() in currentIndex) {
                // current skill is still in the index, so it wasn't present in
                // to_merge it's no longer valid and should be deleted
                self.mission_skills.splice(i, 1);
            } else {
                // current skill was already in to_merge, so skip
                i++;
            }
        }
        for (i = 0; i < skillsNotInCurrent.length; i++) {
            // remaining skills from to_merge should be added with _destroy so
            // they get deleted next submit
            new_skill = skillsNotInCurrent[i];
            new_skill = new MissionSkill(new_skill.id, new_skill.req_vols, 
                    new_skill.skill_id);
            new_skill._destroy(true);
            self.mission_skills.push(new_skill);
        }
    }

    function loadCandidates(candidates) {
        candidates.sort(function(a, b) {
            return a.volunteer.name.localeCompare(b.volunteer.name);
        });
        self.candidates(candidates);
        var lists = { confirmed: [], pending: [], denied: [], unresponsive: [] };
        for (var i = 0; i < candidates.length; i++) {
            var candidate = candidates[i];
            lists[candidate.status].push(new CandidateView(candidate));
        }
        self.confirmed_candidates(lists.confirmed);
        self.pending_candidates(lists.pending);
        self.denied_candidates(lists.denied);
        self.unresponsive_candidates(lists.unresponsive);
    }

    self.loadMissionData = function(data) {
        startForcedUpdate();

        self.id(data.id);
        self.status(data.status);
        self.name(data.name);
        self.reason(data.reason);
        self.address(data.address, true);
        if (data.lat == null || data.lng == null) {
            self.latlng(null);
        } else {
            self.latlng(new google.maps.LatLng(data.lat, data.lng));
        }
        self.farthest(data.farthest);
        self.confirmed_count(data.confirmed_count);

        self.mission_skills.removeAll();
        for (var i = 0; i < data.mission_skills.length; i++) {
            var req_skill = data.mission_skills[i];
            self.mission_skills.push(new MissionSkill(req_skill.id, 
                        req_skill.req_vols, req_skill.skill_id));
        }

        loadCandidates(data.candidates);
    };

}

var model;
$(function() {
    model = new MissionViewModel();
    if (MissionData && MissionData.mission) {
        model.loadMissionData(MissionData.mission);
    }
    ko.applyBindings(model);
});

