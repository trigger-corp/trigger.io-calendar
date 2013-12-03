/* global module, forge, asyncTest, start, ok, askQuestion, equal */
module("forge.calendar");

if (forge.is.mobile()) {
	var calendar = '';
	asyncTest("List calendars", 1, function() {
		forge.calendar.listCalendars(function (calendars) {
			var calout = '';
			for (var i = 0; i < calendars.length; i++) {
				if (i === 0) {
					calendar = calendars[i].id;
				}
				calout += '<span style="background-color: '+calendars[i].color+'"> &nbsp; </span>&nbsp;'+calendars[i].title+"<br>";
			}
			askQuestion("Are these your calendars?<br>"+calout, {
				Yes: function () {
					ok(true, "User claims success");
					start();
				},
				No: function () {
					ok(false, "User claims failure");
					start();
				}
			});
		}, function (e) {
			ok(false, "API call failure: "+e.message);
			start();
		});
	});
	asyncTest("Add calendar event", 1, function() {
		askQuestion("Do you want to try to add a calendar event? If yes it should be an event beginning exactly 3 days ago and ending exactly 1 day ago, recurring weekly, with a title, description and location", {
			Yes: function () {
				forge.calendar.addEvent({
					title:'†és† title',
					description: 'abc description',
					location: 'location xyz',
					allday: false,
					start: new Date(new Date().getTime()-1000*86400*3),
					end: new Date(new Date().getTime()-1000*86400*1),
					recurring: 'weekly'
				}, function (eventId) {
					askQuestion("Did the calendar event add correctly? If yes you will be prompted to edit the event, (on iOS make at least 1 change).", {
						Yes: function () {
							forge.calendar.editEvent(eventId, function () {
								askQuestion("Could you edit the event?", {
									Yes: function () {
										forge.calendar.deleteEvent(eventId, function () {
											ok(true, "User claims success");
											start();
										}, function (e) {
											ok(false, "API call failure: "+e.message);
											start();
										});
									},
									No: function () {
										ok(false, "User claims failure");
										start();
									}
								});
							}, function (e) {
								ok(false, "API call failure: "+e.message);
								start();
							});
						},
						No: function () {
							ok(false, "User claims failure");
							start();
						}
					});
				}, function (e) {
					ok(false, "API call failure: "+e.message);
					start();
				});
			},
			No: function () {
				ok(true, "No calendar");
				start();
			}
		});
	});
	asyncTest("Insert calendar event", 3, function() {
		var startDate = new Date(Math.round((new Date().getTime()-1000*86400*3)/1000)*1000);
		forge.calendar.insertEvent({
			title:'†és† title',
			calendar: calendar,
			description: 'abc description',
			location: 'location xyz',
			allday: false,
			start: startDate,
			end: new Date(new Date().getTime()-1000*86400*1),
			recurring: 'weekly'
		}, function (eventId) {
			forge.calendar.updateEvent(eventId, {
				title: 'test title 2'
			}, function (eventId) {
				forge.calendar.getEvent(eventId, function (event) {
					equal(event.start.getTime(), startDate.getTime());
					equal(event.title, "test title 2");
					forge.calendar.deleteEvent(eventId, function () {
						ok(true, "Event deleted");
						start();
					}, function (e) {
						ok(false, "API call failure: "+e.message);
						start();
					});
				}, function (e) {
					ok(false, "API call failure: "+e.message);
					start();
				});
			}, function (e) {
				ok(false, "API call failure: "+e.message);
				start();
			});
		}, function (e) {
			ok(false, "API call failure: "+e.message);
			start();
		});
	});
}
