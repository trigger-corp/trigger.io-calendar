//
//  calendar_Delegate.m
//  ForgeTemplate
//
//  Created by Connor Dunn on 11/01/2013.
//  Copyright (c) 2013 Trigger Corp. All rights reserved.
//

#import "calendar_Delegate.h"

@implementation calendar_Delegate

- (calendar_Delegate*) initWithTask:(ForgeTask *)initTask {
	if (self = [super init]) {
		task = initTask;
		// "retain"
		me = self;
	}
	return self;
}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action {
	[[[ForgeApp sharedApp] viewController] dismissViewControllerHelper:^{
		if (action == EKEventEditViewActionCanceled || action == EKEventEditViewActionDeleted) {
			[task error:@"User cancelled saving event" type:@"EXPECTED_FAILURE" subtype:nil];
		} else {
			[task success:controller.event.eventIdentifier];
		}
		// "release"
		me = nil;
	}];
}

@end
