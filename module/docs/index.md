``calendar``: Calendar manipulation
===================================

The ``forge.calendar`` namespace allows calendar events to be added to
the native calendar

##API

!method: forge.calendar.addEvent(options, success, error)
!platforms: iOS, Android
!param: options `object` parameters to define the event
!param: success `function(eventId)`
!param: error `function(content)` called with details of any error which may occur
!description: Show a UI that allows the user to add a calendar event, with certain properties pre-filled.

The properties that can be set on the options object are:

* ``title``: The title of the event
* ``description``: The event description (appears as notes on iOS)
* ``location``: The location of the event
* ``start``: The time the event starts (a JavaScript ``Date`` object)
* ``end``: The time the event ends (a JavaScript ``Date`` object)
* ``allday``: A boolean value that determines whether the event is an
   all day event (the time of day in the start and end will be ignored
   in all day events)
* ``recurring``: Whether the event is recurring and how often, one of:
   ``not``, ``daily``, ``weekly``, ``monthly``, or ``yearly``. If not
   specified the event will not recur.

> ::Warning:: On Android the eventId which is returned is the ID of the most recently added event, if another event happened to be added before the user returned to your app this ID could be incorrect.

**Example:**

    forge.calendar.addEvent({
        title: "Anniversary of adding my first event",
        start: new Date(),
        end: new Date(),
        allday: true,
        recurring: "yearly"
    }, function () {
        alert("Event added!");
    });

!method: forge.calendar.listCalendars(success, error)
!platforms: iOS, Android
!param: success `function(calendars)` called with an array of calendar objects, each containing `id`, `name`, and `color` properties
!param: error `function(content)` called with details of any error which may occur
!description: Get a list of the users calendars, primarily to be used in conjuction with forge.calendar.insertEvent, which requires a calendar id.

!method: forge.calendar.insertEvent(details, success, error)
!platforms: iOS, Android
!param: details `object` parameters to define the event
!param: success `function(eventId)`
!param: error `function(content)` called with details of any error which may occur
!description: Programmatically insert an event into the users calendar, this will not prompt the user or show a UI before inserting.

When inserting an event the following fields are required:

* ``calendar``: The id of the calendar to insert into (use ``forge.calendar.listCalendars`` for a list of available calendars)
* ``title``: The title of the event
* ``start``: The time the event starts (a JavaScript ``Date`` object)
* ``end``: The time the event ends (a JavaScript ``Date`` object)

The following options fields can also be included:

* ``description``: The event description (appears as notes on iOS)
* ``location``: The location of the event
* ``allday``: A boolean value that determines whether the event is an
   all day event (the time of day in the start and end will be ignored
   in all day events)
* ``recurring``: Whether the event is recurring and how often, one of:
   ``not``, ``daily``, ``weekly``, ``monthly``, or ``yearly``. If not
   specified the event will not recur.

!method: forge.calendar.updateEvent(eventId, details, success, error)
!platforms: iOS, Android
!param: eventId `string` id of the event to be updated
!param: details `object` parameters to update
!param: success `function(eventId)`
!param: error `function(content)` called with details of any error which may occur
!description: Programmatically update an existing event, this will update any of the details given for an existing event.

When updating an event any combination of the following fields can be included in the details object:

* ``title``: The title of the event
* ``start``: The time the event starts (a JavaScript ``Date`` object)
* ``end``: The time the event ends (a JavaScript ``Date`` object)
* ``description``: The event description (appears as notes on iOS)
* ``location``: The location of the event
* ``allday``: A boolean value that determines whether the event is an
   all day event (the time of day in the start and end will be ignored
   in all day events)
* ``recurring``: Whether the event is recurring and how often, one of:
   ``not``, ``daily``, ``weekly``, ``monthly``, or ``yearly``. If not
   specified the event will not recur.

!method: forge.calendar.getEvent(eventId, success, error)
!platforms: iOS, Android
!param: eventId `string` id of the event to be loaded
!param: success `function(eventDetails)`
!param: error `function(content)` called with details of any error which may occur
!description: Read info about a given eventId.

The `eventDetails` object can contain the following fields:

* ``id``: The id of the event
* ``calendar``: The id of the calendar containing the event
* ``title``: The title of the event
* ``start``: The time the event starts (a JavaScript ``Date`` object)
* ``end``: The time the event ends (a JavaScript ``Date`` object)
* ``description``: The event description (appears as notes on iOS)
* ``location``: The location of the event
* ``allday``: A boolean value that determines whether the event is an
   all day event (the time of day in the start and end will be ignored
   in all day events)

!method: forge.calendar.getEvents(options, success, error)
!platforms: iOS, Android
!param: options `object` Contains either a `from`, `to` date or both to filter events
!param: success `function(eventDetails)` Called with an array of matching events
!param: error `function(content)` called with details of any error which may occur
!description: Load data on all events in a given date range. See getEvent for details on returned fields.

!method: forge.calendar.deleteEvent(eventId, success, error)
!platforms: iOS, Android
!param: eventId `string` id of the event to be deleted
!param: success `function()`
!param: error `function(content)` called with details of any error which may occur
!description: Remove a given eventId from the users calendar.

> ::Warning:: This will not prompt the user, Apple App Store guidelines require you prompt the user before performing a destructive action on the users calendar.

!method: forge.calendar.editEvent(eventId, success, error)
!platforms: iOS, Android
!param: eventId `string` id of the event to be edited
!param: success `function()`
!param: error `function(content)` called with details of any error which may occur
!description: Display a UI allowing the user to edit an existing event based on the eventId

> ::Warning:: On many Android devices there is a bug with the UI to edit calendar events which means the user will be shown the event but will be unable to edit most fields. This API method is only really safe to use on iOS, if you want the user to be able to edit events on Android then you should create your own UI using forge.calendar.getEvent and forge.calendar.updateEvent.