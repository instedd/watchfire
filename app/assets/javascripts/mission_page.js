function onMissionPage() {
    extendKnockout();

    $(function() {
        var model = new MissionViewModel();
        if (MissionData && MissionData.mission) {
            model.loadMissionData(MissionData);
        }
        ko.applyBindings(model);

        // bind mission skills ux-nstep elements, since the elements are
        // dynamically created, and instedd platform binds the click event
        // specifically to the arrow buttons
        function ux_nstep(button, step) {
            var elt = $(button).prevAll('input')[0],
                req_skill = ko.dataFor(elt),
                currentValue;
            if (req_skill && !$(elt).attr('readonly') && !$(elt).attr('disabled')) {
                currentValue = req_skill.req_vols();
                req_skill.req_vols(currentValue + step);
            }
        }
        $('.mission_skills').delegate('.kdown', 'click', function(evt) {
            ux_nstep(this, -1);
        });
        $('.mission_skills').delegate('.kup', 'click', function(evt) {
            ux_nstep(this, +1);
        });
    });
}

