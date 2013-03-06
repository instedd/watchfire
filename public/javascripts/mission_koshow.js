function MissionViewModel() {
    var self = this;

    self.name = ko.observable('');
    self.reason = ko.observable('');
    self.mission_skills = ko.observableArray();

    self.title = ko.computed(function() {
        var result = 'New Event';
        if (self.name()) {
            result = self.name();
            if (self.reason()) {
                result += ' (' + self.reason() + ')';
            }
        }
        return result;
    });

    self.addMissionSkill = function() {
        self.mission_skills.push({ req_vols: 1, skill_id: null });
    };
    self.removeMissionSkill = function(skill) {
        self.mission_skills.remove(skill);
    };

    self.addMissionSkill();
}

var model = new MissionViewModel();
$(function() {
    ko.applyBindings(model);
});

