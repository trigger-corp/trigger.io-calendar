//
//  calendar_Util.h
//  ForgeModule
//
//  Created by Connor Dunn on 08/11/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>

@interface calendar_Util : NSObject

+ (NSDictionary*) dictionaryForEvent:(EKEvent*)event;

@end
