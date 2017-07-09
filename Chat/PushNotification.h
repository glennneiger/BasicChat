//
//  PushNotification.h
//  MessagingExample
//
//  Created by Dan Park on 7/6/17.
//  Copyright © 2017 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PushNotification : NSObject

+ (instancetype)sharedInstance;
+ (void)sendNotificatino:(NSString *)message;
+ (void)notifyToToken:(NSString *)token withMessage:(NSString *)message;
    
+ (NSString *)timestampString;
+ (NSDateFormatter *)formatter;
+ (NSString *)registeredToken;
@end
