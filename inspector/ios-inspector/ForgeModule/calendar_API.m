//
//  calendar_API.m
//  ForgeTemplate
//
//  Created by Connor Dunn on 11/01/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import "calendar_API.h"
#import "calendar_Delegate.h"
#import "calendar_Util.h"
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>

typedef void (^EventAccessBlock_t)(BOOL granted, NSError *error);

@implementation calendar_API

+ (void)listCalendars:(ForgeTask*)task {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *error) {
		NSArray *calendars = nil;
		if ([eventStore respondsToSelector:@selector(calendarsForEntityType:)]) {
			calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
		} else {
			calendars = [eventStore calendars];
		}
		
		NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[calendars count]];
		for (EKCalendar *calendar in calendars) {
			if (calendar.allowsContentModifications) {
				[result addObject:@{
					@"id": calendar.calendarIdentifier,
					@"title": calendar.title,
					@"color": [NSString stringWithFormat:@"#%02X%02X%02X", (int)((CGColorGetComponents(calendar.CGColor))[0]*255.0), (int)((CGColorGetComponents(calendar.CGColor))[1]*255.0), (int)((CGColorGetComponents(calendar.CGColor))[2]*255.0)]
				}];
			}
		}
		[task success:result];
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)addEvent:(ForgeTask*)task details:(NSDictionary*)details {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!granted) {
				[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
				return;
			}
			
			EKEvent *event = [EKEvent eventWithEventStore:eventStore];
			
			event.title = [details objectForKey:@"title"];
			event.location = [details objectForKey:@"location"];
			event.notes = [details objectForKey:@"description"];
			if ([details objectForKey:@"start"] != nil) {
				event.startDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"start"]) doubleValue]];
			}
			if ([details objectForKey:@"end"] != nil) {
				event.endDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"end"]) doubleValue]];
			}
			if ([details objectForKey:@"allday"] != nil) {
				event.allDay = [((NSNumber*)[details objectForKey:@"allday"]) boolValue];
			}
			if ([details objectForKey:@"recurring"] != nil) {
				NSString* recurring = [details objectForKey:@"recurring"];
				if ([recurring isEqualToString:@"daily"]) {
					[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil]];
				} else if ([recurring isEqualToString:@"weekly"]) {
					[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil]];
				} else if ([recurring isEqualToString:@"monthly"]) {
					[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly interval:1 end:nil]];
				} else if ([recurring isEqualToString:@"yearly"]) {
					[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyYearly interval:1 end:nil]];
				}
			}
			
			EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];

			addController.eventStore = eventStore;
			addController.event = event;
			
			addController.editViewDelegate = [[calendar_Delegate alloc] initWithTask:task];
			
			[[[ForgeApp sharedApp] viewController] presentModalViewController:addController animated:YES];
		});
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (EKCalendar *)calendarLookup:(ForgeTask *)task eventStore:(EKEventStore *)eventStore calendarID:(NSString *)calendarID {
    EKCalendar *calendar = [eventStore calendarWithIdentifier:calendarID];
    
    if (!calendar) {
        [task error:@"Calendar does not exist" type:@"EXPECTED_FAILURE" subtype:nil];
        return nil;
    }
    
    if (![calendar allowsContentModifications]) {
        [task error:@"Calendar is read-only" type:@"EXPECTED_FAILURE" subtype:nil];
        return nil;
    }

    return calendar;
}

+ (EKEvent *)newEKEvent:(ForgeTask *)task eventStore:(EKEventStore *)eventStore details:(NSDictionary *)details {
    EKEvent *event = [EKEvent eventWithEventStore:eventStore];
    
    event.calendar = [self calendarLookup:task eventStore:eventStore calendarID:[details objectForKey:@"calendar"]];

    if (!event.calendar) {
        return nil;
    }
    
    event.title = [details objectForKey:@"title"];
    event.location = [details objectForKey:@"location"];
    event.notes = [details objectForKey:@"description"];

    if ([details objectForKey:@"start"] != nil) {
        event.startDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"start"]) doubleValue]];
    }

    if ([details objectForKey:@"end"] != nil) {
        event.endDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"end"]) doubleValue]];
    }

    if ([details objectForKey:@"allday"] != nil) {
        event.allDay = [((NSNumber*)[details objectForKey:@"allday"]) boolValue];
    }

    if ([details objectForKey:@"recurring"] != nil) {
        NSString* recurring = [details objectForKey:@"recurring"];
        if ([recurring isEqualToString:@"daily"]) {
            [event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil]];
        } else if ([recurring isEqualToString:@"weekly"]) {
            [event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil]];
        } else if ([recurring isEqualToString:@"monthly"]) {
            [event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly interval:1 end:nil]];
        } else if ([recurring isEqualToString:@"yearly"]) {
            [event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyYearly interval:1 end:nil]];
        }
    }

    return event;
}

+ (NSString *)doInsert:(ForgeTask *)task eventStore:(EKEventStore *)eventStore details:(NSDictionary *)details {
    NSError *error = nil;
    EKEvent *event = [self newEKEvent:task eventStore:eventStore details:details];
    
    if (!event) {
        return nil;
    }
    
    [eventStore saveEvent:event span:EKSpanFutureEvents error:&error];
    
    if (error) {
        [ForgeLog e:error];
        [task error:@"Failed to insert event" type:@"UNEXPECTED_FAILURE" subtype:nil];
        return nil;
    }
    else {
        return event.eventIdentifier;
    }
}

+ (BOOL)doDelete:(ForgeTask *)task eventStore:(EKEventStore *)eventStore eventID:(NSString *)eventID {
    EKEvent *event = [eventStore eventWithIdentifier:eventID];
    
    if (!event) {
        [task error:@"Event does not exist" type:@"EXPECTED_FAILURE" subtype:nil];
        return NO;
    }
    
    NSError *error = nil;
    
    [eventStore removeEvent:event span:EKSpanFutureEvents error:&error];
    
    if (error) {
        [task error:@"Failed to remove event" type:@"UNEXPECTED_FAILURE" subtype:nil];
        return NO;
    }
    else {
        return YES;
    }
}

+ (BOOL)doCommit:(ForgeTask *)task eventStore:(EKEventStore *)eventStore {
    NSError *error = nil;

    [eventStore commit:&error];

    if (error) {
        [ForgeLog e:error];
        [task error:@"Failed to commit events" type:@"UNEXPECTED_FAILURE" subtype:nil];
        return NO;
    }
    else {
        return YES;
    }
}

+ (void)insertEvent:(ForgeTask*)task details:(NSDictionary*)details {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *err) {
		if (!granted) {
			[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}

        NSString *eventID = [self doInsert:task eventStore:eventStore details:details];
        
        if (eventID) {
            if ([self doCommit:task eventStore:eventStore]) {
                [task success:eventID];
            }
        }
        // If no eventID, the error has already been logged.
    };
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)insertManyEvents:(ForgeTask*)task eventDetails:(NSArray *)eventDetails {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *err) {
		if (!granted) {
			[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:[eventDetails count]];
        BOOL anyFailures = NO;
        
        for (NSDictionary *details in eventDetails) {
        	usleep(300);
            NSString *eventID = [self doInsert:task eventStore:eventStore details:details];
            
            if (eventID) {
                [results addObject:eventID];
            }
            else {
                anyFailures = YES;
                
                for (NSString *eventID in results) {
                    (void)[self doDelete:task eventStore:eventStore eventID:eventID];
                }
                
                break;
            }
        }
        
        if (!anyFailures) {
            if ([self doCommit:task eventStore:eventStore]) {
                [task success:results];
            }
        }
        
        // As usual, if anything's gone wrong, the error is already reported.
    };
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)updateEvent:(ForgeTask*)task eventId:(NSString*)eventId details:(NSDictionary*)details {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *err) {
		if (!granted) {
			[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		EKEvent *event = [eventStore eventWithIdentifier:eventId];
		
		if (!event) {
			[task error:@"Event does not exist" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		EKCalendar* calendar = event.calendar;
		
		if (![calendar allowsContentModifications]) {
			[task error:@"Event calendar is read-only" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		if ([details objectForKey:@"title"] != nil) {
			event.title = [details objectForKey:@"title"];
		}
		if ([details objectForKey:@"location"] != nil) {
			event.location = [details objectForKey:@"location"];
		}
		if ([details objectForKey:@"description"] != nil) {
			event.notes = [details objectForKey:@"description"];
		}
		if ([details objectForKey:@"start"] != nil) {
			event.startDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"start"]) doubleValue]];
		}
		if ([details objectForKey:@"end"] != nil) {
			event.endDate = [NSDate dateWithTimeIntervalSince1970:[((NSNumber*)[details objectForKey:@"end"]) doubleValue]];
		}
		if ([details objectForKey:@"allday"] != nil) {
			event.allDay = [((NSNumber*)[details objectForKey:@"allday"]) boolValue];
		}
		if ([details objectForKey:@"recurring"] != nil) {
			NSArray *rules = [event recurrenceRules];
			for (EKRecurrenceRule* rule in rules) {
				[event removeRecurrenceRule:rule];
			}
			NSString* recurring = [details objectForKey:@"recurring"];
			if ([recurring isEqualToString:@"daily"]) {
				[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyDaily interval:1 end:nil]];
			} else if ([recurring isEqualToString:@"weekly"]) {
				[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:1 end:nil]];
			} else if ([recurring isEqualToString:@"monthly"]) {
				[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyMonthly interval:1 end:nil]];
			} else if ([recurring isEqualToString:@"yearly"]) {
				[event addRecurrenceRule:[[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyYearly interval:1 end:nil]];
			}
		}
		
		NSError *error = nil;
		[eventStore saveEvent:event span:EKSpanFutureEvents error:&error];
		if (error) {
			[task error:@"Failed to update event" type:@"UNEXPECTED_FAILURE" subtype:nil];
		} else {
			[task success:event.eventIdentifier];
		}
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)getEvent:(ForgeTask*)task eventId:(NSString*)eventId {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *error) {
		if (!granted) {
			[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		EKEvent *event = [eventStore eventWithIdentifier:eventId];
		
		if (!event) {
			[task error:@"Event does not exist" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
		[task success:[calendar_Util dictionaryForEvent:event]];
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)editEvent:(ForgeTask*)task eventId:(NSString*)eventId {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (!granted) {
				[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
				return;
			}
			
			EKEvent *event = [eventStore eventWithIdentifier:eventId];
			
			if (!event) {
				[task error:@"Event does not exist" type:@"EXPECTED_FAILURE" subtype:nil];
				return;
			}
						
			EKEventEditViewController *editController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];

			editController.eventStore = eventStore;
			editController.event = event;
			
			editController.editViewDelegate = [[calendar_Delegate alloc] initWithTask:task];
			
			[[[ForgeApp sharedApp] viewController] presentModalViewController:editController animated:YES];
		});
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)deleteEvent:(ForgeTask*)task eventId:(NSString*)eventId {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *err) {
		if (!granted) {
			[task error:@"User denied calendar access" type:@"EXPECTED_FAILURE" subtype:nil];
			return;
		}
		
        if ([self doDelete:task eventStore:eventStore eventID:eventId]) {
            if ([self doCommit:task eventStore:eventStore]) {
                [task success:nil];
            }
        }

        // If something went wrong, the error is already reported.
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

+ (void)getEvents:(ForgeTask*)task from:(NSNumber*)from to:(NSNumber*)to {
	EKEventStore *eventStore = [[EKEventStore alloc] init];
	
	EventAccessBlock_t eventAccess = ^(BOOL granted, NSError *err) {
		NSMutableArray *events = [[NSMutableArray alloc] init];
		[eventStore enumerateEventsMatchingPredicate:[eventStore predicateForEventsWithStartDate:[NSDate dateWithTimeIntervalSince1970:[from doubleValue]] endDate:[NSDate dateWithTimeIntervalSince1970:[to doubleValue]] calendars:[eventStore calendars]] usingBlock:^(EKEvent *event, BOOL *stop) {
			[events addObject:[calendar_Util dictionaryForEvent:event]];
		}];
		[task success:events];
	};
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		[eventStore requestAccessToEntityType:EKEntityTypeEvent completion:eventAccess];
	} else {
		eventAccess(YES, nil);
	}
}

@end
