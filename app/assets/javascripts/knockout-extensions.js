function extendKnockout() {
    ko.extenders.trim = function(target) {
        var result = ko.computed({
            read: target,
            write: function(newValue) {
                var current = target(),
                    valueToWrite = (newValue || '').trim();
                if (valueToWrite !== current) {
                    target(valueToWrite);
                } else if (newValue !== current) {
                    target.notifySubscribers(valueToWrite);
                }
            }
        });
        result(target());
        return result;
    };

    ko.extenders.integer = function(target, minValue, maxValue) {
        var result = ko.computed({
            read: target,
            write: function(newValue) {
                var current = target(), valueToWrite;
                valueToWrite = parseInt(+newValue);
                if (minValue != null) {
                    valueToWrite = Math.max(minValue, valueToWrite);
                }
                if (maxValue != null) {
                    valueToWrite = Math.min(maxValue, valueToWrite);
                }
                if (valueToWrite !== current) {
                    target(valueToWrite);
                } else if (newValue !== current) {
                    target.notifySubscribers(valueToWrite);
                }
            }
        });
        result(target());
        return result;
    };

    ko.bindingHandlers.timeago = {
        init: function(element, valueAccessor) {
            var value = valueAccessor();
            $(element).attr('title', value).timeago();
        },
        update: function(element, valueAccessor) {
            var value = valueAccessor();
            $(element).attr('title', value);
        }
    };
}

