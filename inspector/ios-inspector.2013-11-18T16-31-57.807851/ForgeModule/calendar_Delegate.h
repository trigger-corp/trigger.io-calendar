//
//  calendar_Delegate.h
//  ForgeTemplate
//
//  Created by Connor Dunn on 11/01/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EventKitUI/EventKitUI.h>

@interface calendar_Delegate : NSObject <EKEventEditViewDelegate> {
	ForgeTask* task;
	calendar_Delegate* me;
}

- (calendar_Delegate*) initWithTask:(ForgeTask *)initTask;

@end
