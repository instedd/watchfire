function MissionSkillViewModel(id, req_vols, skill_id) {
    var self = this;
    self.id = ko.observable(id);
    self.req_vols = ko.observable(req_vols).extend({ integer: 1 });
    self.skill_id = ko.observable(skill_id);
    self._destroy = ko.observable(false);
    self.availableSkills = ko.observableArray();
}

function CandidateViewModel(data) {
    // data is a candidate object from the JSON view
    var self = this;
    for (var prop in data) {
        self[prop] = data[prop];
    }

    self.isPending = data.status == 'pending';
    self.active = ko.observable(data.active);

    var current_voice_number = data.last_call && data.last_call.voice_number;
    function buildNumbers(collection, spanClass, disabledClass) {
        var result = [];
        for (var i = 0; i < collection.length; i++) {
            var address = collection[i].address;
            var active = (self.active() && self.isPending) || address == data.answered_from;
            if (address == current_voice_number) {
                address += ' (' + data.voice_status + ')';
            }
            result.push($('<span>').text(address).
                    addClass(active ? spanClass : disabledClass).
                    wrap('<p>').parent().html());
        }
        return result.join('<br>');
    }
    self.volunteer.sms_numbers = ko.computed(function() {
        return buildNumbers(data.volunteer.sms_channels, 'mobile', 'gmobile');
    });
    self.volunteer.voice_numbers = ko.computed(function() {
        return buildNumbers(data.volunteer.voice_channels, 'phone', 'gphone');
    });
}

function MissionViewModel() {
    var self = this;

    // DefaultSkill and ActiveSkills are defined by the view
    self.activeSkills = [DefaultSkill].concat(ActiveSkills || []);
    var skillMap = {};
    $.each(self.activeSkills, function(index, skill) {
        skillMap[skill.id] = skill;
    });
    self.urls = {};

    // mission hidden fields
    self.id = ko.observable();
    self.errors = ko.observable({});
    self.latlng = ko.observable(null);
    self.status = ko.observable('created');
    self.farthest = ko.observable(0);
    self.confirmed_count = ko.observable(0);

    // mission editable fields
    self.name = ko.observable('').extend({ trim: true });
    self.reason = ko.observable('').extend({ trim: true });
    self.mission_skills = ko.observableArray();
    self.intro_text = ko.observable('').extend({ trim: true });
    self.desc_text = ko.observable('').extend({ trim: true });
    self.question_text = ko.observable('').extend({ trim: true });
    self.yes_text = ko.observable('').extend({ trim: true });
    self.no_text = ko.observable('').extend({ trim: true });
    self.confirm_human = ko.observable(true);
    self.location_type = ko.observable('city');
    self.city = ko.observable();
    self.forward_address = ko.observable('');

    // candidates lists
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
    self.limited_reason = ko.computed(function() {
        var reason = self.reason();
        if (reason && reason.length > 200) {
            reason = reason.substr(0, 197) + '...';
        }
        return reason;
    });
    self.title = ko.computed(function() {
        var result = 'New Event';
        var req_skills = self.mission_skills();
        var name = self.name();
        var reason = self.limited_reason();
        if (name) {
            result = name;
            req_skills = $.map($.grep(req_skills, function(req_skill) {
                return !req_skill._destroy();
            }), function(req_skill) {
                var req_vols = req_skill.req_vols();
                var skill = skillMap[req_skill.skill_id()] || DefaultSkill;
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
    self.availableSkills = ko.computed(function() {
        var req_skills = self.mission_skills(),
            taken = [],
            available = [].concat(self.activeSkills),
            i = 0;

        for (i = 0; i < req_skills.length; i++) {
            if (req_skills[i]._destroy()) continue;
            var skill_id = req_skills[i].skill_id();
            if (taken.indexOf(skill_id) < 0) {
                taken.push(skill_id);
            }
        }
        i = 0;
        while (i < available.length) {
            var skill_id = available[i].id;
            if (taken.indexOf(skill_id) >= 0) {
                available.splice(i, 1);
            } else {
                i++;
            }
        }
        return available;
    });
    self.availableSkills.subscribe(function(available) {
        var req_skills = self.mission_skills(), i = 0;

        for (i = 0; i < req_skills.length; i++) {
            if (req_skills[i]._destroy()) continue;
            var current = skillMap[req_skills[i].skill_id()];
            var req_available = (current ? [current] : []).concat(available);
            req_skills[i].availableSkills(req_available);
        }
    });
    self.distanceLegend = ko.computed(function() {
        if (self.status() == 'running') {
            return 'Calling volunteers up to';
        } else {
            return 'Will call volunteers up to';
        }
    });
    self.isCreated = ko.computed(function() {
        return self.status() == 'created';
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
        switch (self.status()) {
            case 'created':
                return 'Start recruiting';
            case 'running':
                return 'Pause recruiting';
            case 'paused':
                return 'Resume recruiting';
            default:
                return 'Open event';
        }
    });
    self.buttonCss = ko.computed(function() {
        switch (self.status()) {
            case 'created':
                return 'orange' + (self.id() ? '' : ' disabled');
            case 'running':
            case 'paused':
                return 'white';
            default:
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
        return self.limited_reason() || 'a single house fire';
    });
    self.address_with_default = ko.computed(function() {
        return self.address() || '1710 Trousdale, Burlingame';
    });

    // behavior methods
    self.addMissionSkill = function() {
        if (self.status() == 'created') {
            var available_skill = self.availableSkills()[0];
            self.mission_skills.push(
                    new MissionSkillViewModel(null, 1, 
                        available_skill ? available_skill.id : null));
        }
    };
    self.removeMissionSkill = function(skill) {
        if (self.status() == 'created') {
            if (skill.id) {
                skill._destroy(true);
            } else {
                self.mission_skills.remove(skill);
            }
        }
    };
    self.findRecruitees = function() {
        // nothing to do here for now
        // just unfocusing the address field will trigger a data submit
    };
    self.startStop = function() {
        if (!self.id()) {
            return;
        }
        switch (self.status()) {
            case 'created':
            case 'paused':
                immediateSubmit('start');
                break;
            case 'running':
                immediateSubmit('stop');
                break;
            default:
                if (self.urls.open) {
                    var form = createForm('POST', self.urls.open);
                    form.submit();
                }
                break;
        }
    };
    self.enableAll = function() {
        immediateSubmit('enableAll');
    };
    self.disableAll = function() {
        immediateSubmit('disableAll');
    };
    self.toggleCandidate = function(candidate) {
        $.ajax({
            type: 'PUT',
            url: candidate.url,
            dataType: 'json',
            data: { candidate: { active: candidate.active() }}
        });
        return true;
    };
    self.showCandidate = function(candidate) {
        var volunteer = candidate.volunteer;
        var location = new google.maps.LatLng(volunteer.lat, volunteer.lng);

        $.get(candidate.volunteer.url, function(data) {
            self.mapView.showVolunteerData(location, data);
        });
    };
    self.exportData = function() {
        if (self.urls.export) {
            window.location.href = self.urls.export;
        }
    };
    self.deleteMission = function() {
        if (self.id() && confirm('Are you sure?')) {
            var form = createForm('DELETE', self.urls.update);
            form.submit();
        }
    };

    // UI related
    self.current_edit_message = ko.observable('');

    self.edit_message = function(name) {
        self.current_edit_message(name);
    };

    // initialization
    self.addMissionSkill();
    self.mapView = new MapView();
    self.mapView.enableMarkerDrag();

    // event binding with the map view (mostly)
    self.latlng.subscribe(function(newValue) {
        self.mapView.setMissionLocation(newValue);
    });
    self.mapView.onMarkerChanged = function(location) {
        self.latlng(location);
        reverseGeocode(location);
    };
    self.isRunningOrFinished.subscribe(function(runningOrFinished) {
        if (runningOrFinished) {
            $('.TaskBox').addClass('readonly');
        } else {
            $('.TaskBox').removeClass('readonly');
        }
    });
    self.isRunning.subscribe(function(running) {
        if (running) {
            self.mapView.startBeating();
            startRefresh();
        } else {
            self.mapView.stopBeating();
            stopRefresh();
        }
    });
    self.isCreated.subscribe(function(created) {
        if (created) {
            self.mapView.enableMarkerDrag();
        } else {
            self.mapView.disableMarkerDrag();
        }
    });
    self.farthest.subscribe(function(newRadius) {
        self.mapView.setRecruitRadius(newRadius);
    });

    // geocoding and reverse-geocoding
    var geocoder = new google.maps.Geocoder();
    function geocodeAddress(address) {
        geocoder.geocode({ 'address': address }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                var location = results[0].geometry.location;
                self.latlng(location);
                self.city(find_city(results[0]));
            } else {
                alert("Location not found");
                self.city('');
            }
        });
    }
    function reverseGeocode(location) {
        geocoder.geocode({ 'latLng': location }, function(results, status) {
            if (status == google.maps.GeocoderStatus.OK) {
                if (results[0]) {
                    // save address, but prevent further geocoding
                    self.address(results[0].formatted_address, true);
                    self.city(find_city(results[0]));
                }
            } else {
                alert("Reverse Geocoding failed");
                self.address('');
                self.city('');
            }
        });
    }
    function find_city(result) {
        var city = null;
        for(var i = 0; i < result.address_components.length; i++) {
            component = result.address_components[i];
            if (component.types[0] == 'locality') {
                city = component.long_name;
            }
        }
        return city;
    }

    // save & load code
    var submitData = ko.computed(function() {
        var location = self.latlng();
        var prio = 1;
        var mission_skills = $.map(self.mission_skills(), function(ms) {
            var result = {
                req_vols: ms.req_vols(),
                skill_id: ms.skill_id() || '',
                priority: prio
            };
            if (ms.id()) {
                result.id = ms.id();
                if (ms._destroy()) {
                    result._destroy = true;
                }
            }
            if (!ms._destroy()) {
                prio++;
            }
            return result;
        });

        return {
            name: self.name() || '',
            address: self.address() || '',
            city: self.city() || '',
            reason: self.reason() || '',
            messages: {
                intro_text: self.intro_text() || '',
                desc_text: self.desc_text() || '',
                question_text: self.question_text() || '',
                yes_text: self.yes_text() || '',
                no_text: self.no_text() || '',
                location_type: self.location_type() || 'city',
                confirm_human: self.confirm_human() ? '1' : '0'
            },
            forward_address: self.forward_address() || '',
            lat: location && location.lat(),
            lng: location && location.lng(),
            mission_skills_attributes: mission_skills
        };
    });

    self.dirty = ko.observable(false);
    self.saving = ko.observable(false);

    var merging = false;
    // this function is to stop data submits if we have to change the model
    // programmatically, which would in turn recompute submitData and enqueue a
    // new submit
    function startForcedUpdate() {
        merging = true;
        // reset flag in a timeout because submitData maybe throttled
        setTimeout(function() { merging = false; }, 20);
    }
    submitData.subscribe(function(newValue) {
        // enqueue a data submit unless we're in the middle of a programmatic
        // model change
        if (merging) {
            return;
        }
        self.dirty(true);
        delayedSubmit();
    });

    var submitTimeout = null;
    var pendingSubmit = null;
    var submitQueue = [];

    function submitPrologue(type) {
        type = type || 'update';
        if (submitQueue[0] != type && (type == 'update' ||
                !pendingSubmit || pendingSubmit.submitType != type)) {
            // queue submission if different from the last queued event and
            // from the current pending one (unless it's an update, which is
            // allowed since the user might have changed the form data since
            // last submit)
            submitQueue.unshift(type);
        }
        if (submitTimeout) {
            clearTimeout(submitTimeout);
            submitTimeout = null;
        }
    }
    function delayedSubmit(type) {
        submitPrologue(type);
        submitTimeout = setTimeout(function() {
            submitTimeout = null;
            checkQueue();
        }, 500);
    }
    function immediateSubmit(type) {
        submitPrologue(type);
        checkQueue();
    }
    function checkQueue() {
        // avoid double submit; ie. wait for the previous submit to
        // complete
        if (submitQueue.length > 0 && pendingSubmit == null) {
            runQueue();
        }
    }
    function runQueue() {
        // really submit
        var type = submitQueue.pop();
        var options = {};

        switch (type) {
            case 'update':
                options = {
                    type: self.id() ? 'PUT' : 'POST',
                    url: self.urls.update,
                    data: { mission: submitData() }
                };
                break;
            case 'start':
                options = { type: 'POST', url: self.urls.start };
                break;
            case 'stop':
                options = { type: 'POST', url: self.urls.stop };
                break;
            case 'enableAll':
                options = { type: 'POST', url: self.urls.check_all };
                break;
            case 'disableAll':
                options = { type: 'POST', url: self.urls.uncheck_all };
                break;
            case 'refresh':
                options = { type: 'GET', url: self.urls.update };
                break;
        }
        options = $.extend({
            dataType: 'json',
            data: {},
            success: onSubmitSuccess,
            error: onSubmitError,
            cache: false
        }, options);

        if (!options.url) {
            console.warn('No URL to submit');
            checkQueue();
            return;
        }
        self.saving(true);
        pendingSubmit = $.ajax(options);
        pendingSubmit.submitType = type;
    }

    function onSubmitSuccess(result) {
        // update local model view values
        updateMissionData(result);

        // process error messages
        self.errors(result.errors);

        // update breadcrumb only if the mission is created
        if (result.mission.id) {
            updateBreadCrumb(result.mission.name, result.urls.update);
        }

        if (submitQueue.length == 0) {
            // queue is empty, so no more changes to submit
            self.dirty(false);
        }

        if (pendingSubmit.submitType == 'refresh') {
            queueNextRefresh();
        }
        pendingSubmit = null;
        self.saving(false);
        checkQueue();
    }
    function onSubmitError(xhr, options, err) {
        console.error('Mission submit error', err);

        pendingSubmit = null;
        self.saving(false);
        checkQueue();
    }

    function createForm(method, target) {
        // create a valid rails form by adding the CSRF parameter
        var form = $("<form>").attr('action', target).appendTo(document.body);
        method = (method || 'POST').toUpperCase();
        if (method == 'GET' || method == 'POST') {
            form.attr('method', method);
        } else {
            form.attr('method', 'POST');
            $('<input type="hidden" name="_method">').attr('value', method).
                appendTo(form);
        }
        var csrfName = $('meta[name=csrf-param]').attr('content');
        var csrfValue = $('meta[name=csrf-token]').attr('content');
        $('<input type="hidden">').attr('name', csrfName).
            attr('value', csrfValue).appendTo(form);
        return form;
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
            new_skill = new MissionSkillViewModel(new_skill.id, 
                    new_skill.req_vols, new_skill.skill_id);
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
            lists[candidate.status].push(new CandidateViewModel(candidate));
        }
        self.confirmed_candidates(lists.confirmed);
        self.pending_candidates(lists.pending);
        self.denied_candidates(lists.denied);
        self.unresponsive_candidates(lists.unresponsive);
    }

    function updateBreadCrumb(name, url) {
        $('.BreadCrumb li').last().empty().append(
                $('<a>').text(name).attr('href', url));
        if (window.history && window.history.replaceState) {
            window.history.replaceState({}, document.title, url);
        }
    }

    function updateMissionData(data, initialUpdate) {
        startForcedUpdate();

        var mission = data.mission;

        if (initialUpdate) {
            // this fields are only updated when loading the mission data for the
            // first time
            self.name(mission.name);
            self.reason(mission.reason);
            self.address(mission.address, true);
            self.city(mission.city);
            if (mission.lat === null || mission.lng === null) {
                self.latlng(null);
            } else {
                self.latlng(new google.maps.LatLng(mission.lat, mission.lng));
            }
            self.forward_address(mission.forward_address);

            // initially set the mission skills; will partially update the info on
            // ajax updates
            self.mission_skills.removeAll();
            for (var i = 0; i < mission.mission_skills.length; i++) {
                var req_skill = mission.mission_skills[i];
                self.mission_skills.push(new MissionSkillViewModel(req_skill.id, 
                            req_skill.req_vols, req_skill.skill_id));
            }
        } else {
            mergeMissionSkills(mission.mission_skills);
        }

        // New record
        if (self.id() === null && mission.id) {
            self.intro_text(mission.messages.intro_text);
            self.desc_text(mission.messages.desc_text);
            self.question_text(mission.messages.question_text);
            self.yes_text(mission.messages.yes_text);
            self.no_text(mission.messages.no_text);
            self.location_type(mission.messages.location_type);
            self.confirm_human(mission.messages.confirm_human == '1');
        }

        // update the non-user-editable data for the mission
        self.id(mission.id);
        self.status(mission.status);
        self.farthest(mission.farthest);
        self.confirmed_count(mission.confirmed_count);

        // load the candidates lists
        loadCandidates(mission.candidates);

        self.urls = data.urls;
    }

    self.loadMissionData = function(data) {
        // initial mission data loading
        updateMissionData(data, true);
    };

    // periodic refresh code
    var refreshing = false;
    var refreshTimeout = null;
    var refreshInterval = 5000;
    function queueNextRefresh() {
        if (refreshing && !refreshTimeout) {
            refreshTimeout = setTimeout(function() {
                refreshTimeout = null;
                immediateSubmit('refresh');
            }, refreshInterval);
        }
    }
    function startRefresh() {
        refreshing = true;
        clearTimeout(refreshTimeout);
        refreshTimeout = null;
        queueNextRefresh();
    }
    function stopRefresh() {
        clearTimeout(refreshTimeout);
        refreshTimeout = null;
        refreshing = false;
    }
}


