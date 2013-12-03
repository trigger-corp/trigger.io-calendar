//
//  calendar_Util.m
//  ForgeModule
//
//  Created by Connor Dunn on 08/11/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import "calendar_Util.h"


@implementation calendar_Util

+ (NSDictionary*) dictionaryForEvent:(EKEvent*)event {
	NSMutableDictionary *details = [[NSMutableDictionary alloc] init];
	
	[details setObject:event.eventIdentifier forKey:@"id"];
	[details setObject:event.calendar.calendarIdentifier forKey:@"calendar"];
	if (event.title) {
		[details setObject:event.title forKey:@"title"];
	}
	if (event.location) {
		[details setObject:event.location forKey:@"location"];
	}
	if (event.notes) {
		[details setObject:event.notes forKey:@"description"];
	}
	[details setObject:[NSNumber numberWithDouble:[event.startDate timeIntervalSince1970]] forKey:@"start"];
	[details setObject:[NSNumber numberWithDouble:[event.endDate timeIntervalSince1970]] forKey:@"end"];
	[details setObject:[NSNumber numberWithBool:event.allDay] forKey:@"allday"];
	
	return details;
}

@end
