/* global forge*/

var processEvent = function (event) {
	if (event.start) {
		event.start = new Date(event.start*1000);
	}
	if (event.end) {
		event.end = new Date(event.end*1000);
	}
	return event;
};

forge['calendar'] = {
	'listCalendars': function (success, error) {
		forge.internal.call('calendar.listCalendars', {}, success, error);
	},
	'addEvent': function (details, success, error) {
		if (details.start) {
			details.start = details.start.getTime()/1000;
		}
		if (details.end) {
			details.end = details.end.getTime()/1000;
		}
		forge.internal.call('calendar.addEvent', {details: details}, success, error);
	},
	'insertEvent': function (details, success, error) {
		if (details.start) {
			details.start = details.start.getTime()/1000;
		}
		if (details.end) {
			details.end = details.end.getTime()/1000;
		}
		forge.internal.call('calendar.insertEvent', {details: details}, success, error);
	},
	'insertManyEvents': function (eventDetails, success, error) {
        eventDetails.forEach(function (details) {
            if (details.start) {
                details.start = details.start.getTime()/1000;
            }
            if (details.end) {
                details.end = details.end.getTime()/1000;
            }
        });
        
		forge.internal.call('calendar.insertManyEvents', {eventDetails: eventDetails}, success, error);
	},
	'updateEvent': function (eventId, details, success, error) {
		if (details.start) {
			details.start = details.start.getTime()/1000;
		}
		if (details.end) {
			details.end = details.end.getTime()/1000;
		}
		forge.internal.call('calendar.updateEvent', {eventId: eventId, details: details}, success, error);
	},
	'getEvent': function (eventId, success, error) {
		forge.internal.call('calendar.getEvent', {eventId: eventId}, function (details) {
			details = processEvent(details);
			success && success(details);
		}, error);
	},
	'editEvent': function (eventId, success, error) {
		forge.internal.call('calendar.editEvent', {eventId: eventId}, success, error);
	},
	'deleteEvent': function (eventId, success, error) {
		forge.internal.call('calendar.deleteEvent', {eventId: eventId}, success, error);
	},
	'getEvents': function (params, success, error) {
		forge.internal.call('calendar.getEvents', {
			from: params.from ? params.from.getTime()/1000 : new Date().getTime(),
			to: params.to ? params.to.getTime()/1000 : new Date().getTime()
		}, function (events) {
			for (var event in events) {
				processEvent(events[event]);
			}
			success && success(events);
		}, error);
	}
};
