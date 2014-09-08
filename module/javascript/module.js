/* global forge */

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
	'listCalendars': function (accessLevel, success, error) {
		if (typeof accessLevel === "function") {
			error = success;
			success = accessLevel;
			accessLevel = forge.calendar.ACL.override;
		} else if (typeof accessLevel == "undefined") {
			accessLevel = forge.calendar.ACL.override;
		}
		if (forge.is.android()) {
			forge.internal.call('calendar.listCalendars', { accessLevel: accessLevel }, success, error);
		} else {
			forge.internal.call('calendar.listCalendars', {}, success, error);
		}
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
	},

	// see: http://osxr.org/android/source/frameworks/base/core/java/android/provider/CalendarContract.java
	'ACL': {
		'none': 0,		     // cannot access the calendar
		'freebusy': 100,     // can only see free/busy information about the calendar
		'read': 200,	     // can read all event details
		'respond': 300,	     // can reply yes/no/maybe to an event
		'override': 400,     // not used
		'contributor': 500,  // full access to modify the calendar, but not the access control settings
		'editor': 600,	     // full access to modify the calendar, but not the access control settings
		'owner': 700,	     // full access to the calendar
		'root': 800		     // domain admin
	}
};
