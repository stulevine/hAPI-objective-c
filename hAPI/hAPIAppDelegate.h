//
//  hAPIAppDelegate.h
//  hAPI
//
//  Created by Stuart Levine on 11/12/12.
//  Copyright (c) 2012 Stuart Levine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "hAPIClient.h"

@interface hAPIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) hAPIClient *hAPIClient;

+ (hAPIAppDelegate *)sharedDelegate;

@end
