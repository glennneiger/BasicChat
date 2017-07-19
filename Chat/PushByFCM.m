//
//  AntiGravityEngineFCM.m
//  Chat
//
//  Created by Dan Park on 7/18/17.
//

#import "PushByFCM.h"
@import FirebaseInstanceID;
@import FirebaseMessaging;
@import FirebaseAnalytics;

@implementation PushByFCM {
    void (^completionHandler)(UIBackgroundFetchResult);
}

-(void)initRegistration {
    NSString * registrationToken = [[FIRInstanceID instanceID] token];
    
    if (registrationToken != nil) {
        NSLog(@"FCM Registration Token: %@", registrationToken);
        [self setFcmRegistrationToken: registrationToken];
        
        id topics = [self fcmTopics];
        if (topics != nil) {
            for (NSString *topic in topics) {
                NSLog(@"subscribe from topic: %@", topic);
                id pubSub = [FIRMessaging messaging];
                [pubSub subscribeToTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
            }
        }
        
        [self registerWithToken:registrationToken];
    } else {
        NSLog(@"FCM token is null");
    }
    
}

//  FCM refresh token
//  Unclear how this is testable under normal circumstances
- (void)onTokenRefresh {
#if !TARGET_IPHONE_SIMULATOR
    // A rotation of the registration tokens is happening, so the app needs to request a new token.
    NSLog(@"The FCM registration token needs to be changed.");
    [[FIRInstanceID instanceID] token];
    [self initRegistration];
#endif
}

// contains error info
- (void)sendDataMessageFailure:(NSNotification *)notification {
    NSString *messageID = (NSString *)notification.object;
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"sendDataMessageFailure");
    // Did fail send message
}
- (void)sendDataMessageSuccess:(NSNotification *)notification {
    NSString *messageID = (NSString *)notification.object;
    NSDictionary *userInfo = notification.userInfo;
    NSLog(@"sendDataMessageSuccess");
    // Did successfully send message
}

- (void)willSendDataMessageWithID:(NSString *)messageID error:(NSError *)error {
    NSLog(@"%s", __func__);
}

- (void)didSendDataMessageWithID:(NSString *)messageID {
    NSLog(@"%s", __func__);
}


- (void)didDeleteMessagesOnServer {
    NSLog(@"%s", __func__);
    // Some messages sent to this device were deleted on the GCM server before reception, likely
    // because the TTL expired. The client should notify the app server of this, so that the app
    // server can resend those messages.
}

- (void)unregister:(NSArray*)topics {
    if (topics != nil) {
        id pubSub = [FIRMessaging messaging];
        for (NSString *topic in topics) {
            NSLog(@"unsubscribe from topic: %@", topic);
            [pubSub unsubscribeFromTopic:topic];
        }
    } else {
        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    }
}

- (void)subscribe:(NSString*)topic {
    if (topic != nil) {
        NSLog(@"subscribe from topic: %@", topic);
        id pubSub = [FIRMessaging messaging];
        [pubSub subscribeToTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        NSLog(@"Successfully subscribe to topic %@", topic);
    } else {
        NSLog(@"There is no topic to subscribe");
    }
}

- (void)unsubscribe:(NSString*)topic {
    if (topic != nil) {
        NSLog(@"unsubscribe from topic: %@", topic);
        id pubSub = [FIRMessaging messaging];
        [pubSub unsubscribeFromTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        NSLog(@"Successfully unsubscribe to topic %@", topic);
    } else {
        NSLog(@"There is no topic to unsubscribe");
    }
}

- (void)registerNotifications:(NSMutableDictionary*) options {
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(onTokenRefresh)
     name:kFIRInstanceIDTokenRefreshNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(sendDataMessageFailure:)
     name:FIRMessagingSendErrorNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(sendDataMessageSuccess:)
     name:FIRMessagingSendSuccessNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(didDeleteMessagesOnServer)
     name:FIRMessagingMessagesDeletedNotification object:nil];

    NSLog(@"Push Plugin register called");
    
    NSMutableDictionary* iosOptions = [options objectForKey:@"ios"];
    
    NSArray* topics = [iosOptions objectForKey:@"topics"];
    [self setFcmTopics:topics];
    
    UIUserNotificationType UserNotificationTypes = UIUserNotificationTypeNone;
    
    id badgeArg = [iosOptions objectForKey:@"badge"];
    id soundArg = [iosOptions objectForKey:@"sound"];
    id alertArg = [iosOptions objectForKey:@"alert"];
    id clearBadgeArg = [iosOptions objectForKey:@"clearBadge"];
    
    if (([badgeArg isKindOfClass:[NSString class]] && [badgeArg isEqualToString:@"true"]) || [badgeArg boolValue])
    {
        UserNotificationTypes |= UIUserNotificationTypeBadge;
    }
    
    if (([soundArg isKindOfClass:[NSString class]] && [soundArg isEqualToString:@"true"]) || [soundArg boolValue])
    {
        UserNotificationTypes |= UIUserNotificationTypeSound;
    }
    
    if (([alertArg isKindOfClass:[NSString class]] && [alertArg isEqualToString:@"true"]) || [alertArg boolValue])
    {
        UserNotificationTypes |= UIUserNotificationTypeAlert;
    }
    
    UserNotificationTypes |= UIUserNotificationActivationModeBackground;

    if (clearBadgeArg == nil || ([clearBadgeArg isKindOfClass:[NSString class]] && [clearBadgeArg isEqualToString:@"false"]) || ![clearBadgeArg boolValue]) {
        NSLog(@"PushPlugin.register: setting badge to false");
        _clearBadge = NO;
    } else {
        NSLog(@"PushPlugin.register: setting badge to true");
        _clearBadge = YES;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    }
    NSLog(@"PushPlugin.register: clear badge is set to %d", _clearBadge);
    
    _isInline = NO;
    
    NSLog(@"PushPlugin.register: better button setup");
    // setup action buttons
    NSMutableSet *categories = [[NSMutableSet alloc] init];
    id categoryOptions = [iosOptions objectForKey:@"categories"];
    if (categoryOptions != nil && [categoryOptions isKindOfClass:[NSDictionary class]]) {
        for (id key in categoryOptions) {
            NSLog(@"categories: key %@", key);
            id category = [categoryOptions objectForKey:key];
            
            id yesButton = [category objectForKey:@"yes"];
            UIMutableUserNotificationAction *yesAction;
            if (yesButton != nil && [yesButton  isKindOfClass:[NSDictionary class]]) {
                yesAction = [self createAction: yesButton];
            }
            id noButton = [category objectForKey:@"no"];
            UIMutableUserNotificationAction *noAction;
            if (noButton != nil && [noButton  isKindOfClass:[NSDictionary class]]) {
                noAction = [self createAction: noButton];
            }
            id maybeButton = [category objectForKey:@"maybe"];
            UIMutableUserNotificationAction *maybeAction;
            if (maybeButton != nil && [maybeButton  isKindOfClass:[NSDictionary class]]) {
                maybeAction = [self createAction: maybeButton];
            }
            
            // First create the category
            UIMutableUserNotificationCategory *notificationCategory = [[UIMutableUserNotificationCategory alloc] init];
            
            // Identifier to include in your push payload and local notification
            notificationCategory.identifier = key;
            
            NSMutableArray *categoryArray = [[NSMutableArray alloc] init];
            NSMutableArray *minimalCategoryArray = [[NSMutableArray alloc] init];
            if (yesButton != nil) {
                [categoryArray addObject:yesAction];
                [minimalCategoryArray addObject:yesAction];
            }
            if (noButton != nil) {
                [categoryArray addObject:noAction];
                [minimalCategoryArray addObject:noAction];
            }
            if (maybeButton != nil) {
                [categoryArray addObject:maybeAction];
            }
            
            // Add the actions to the category and set the action context
            [notificationCategory setActions:categoryArray forContext:UIUserNotificationActionContextDefault];
            
            // Set the actions to present in a minimal context
            [notificationCategory setActions:minimalCategoryArray forContext:UIUserNotificationActionContextMinimal];
            
            NSLog(@"Adding category %@", key);
            [categories addObject:notificationCategory];
        }
        
    }
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UserNotificationTypes categories:categories];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    // Read GoogleService-Info.plist
    NSString *path = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    
    // Load the file content and read the data into arrays
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    _fcmSenderId = [dict objectForKey:@"GCM_SENDER_ID"];
    
    NSLog(@"FCM Sender ID %@", _fcmSenderId);
    
    //  GCM options
    [self setFcmSenderId: _fcmSenderId];
    if([[self fcmSenderId] length] > 0) {
        NSLog(@"Using FCM Notification");
        [self setUsesFCM: YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            if([FIRApp defaultApp] == nil)
                [FIRApp configure];
            [self initRegistration];
        });
    } else {
        NSLog(@"Using APNS Notification");
        [self setUsesFCM:NO];
    }
    id fcmSandboxArg = [iosOptions objectForKey:@"fcmSandbox"];
    
    [self setFcmSandbox:@NO];
    if ([self usesFCM] &&
        (([fcmSandboxArg isKindOfClass:[NSString class]] && [fcmSandboxArg isEqualToString:@"true"]) ||
         [fcmSandboxArg boolValue]))
    {
        NSLog(@"Using FCM Sandbox");
        [self setFcmSandbox:@YES];
    }
    
    if (_notificationMessage) {            // if there is a pending startup notification
        dispatch_async(dispatch_get_main_queue(), ^{
            // delay to allow JS event handlers to be setup
            [self performSelector:@selector(notificationReceived) withObject:nil afterDelay: 0.5];
        });
    }
}

- (UIMutableUserNotificationAction *)createAction:(NSDictionary *)dictionary {
    UIMutableUserNotificationAction *myAction = [[UIMutableUserNotificationAction alloc] init];
    
    myAction = [[UIMutableUserNotificationAction alloc] init];
    myAction.identifier = [dictionary objectForKey:@"callback"];
    myAction.title = [dictionary objectForKey:@"title"];
    id mode =[dictionary objectForKey:@"foreground"];
    if (mode == nil || ([mode isKindOfClass:[NSString class]] && [mode isEqualToString:@"false"]) || ![mode boolValue]) {
        myAction.activationMode = UIUserNotificationActivationModeBackground;
    } else {
        myAction.activationMode = UIUserNotificationActivationModeForeground;
    }
    id destructive = [dictionary objectForKey:@"destructive"];
    if (destructive == nil || ([destructive isKindOfClass:[NSString class]] && [destructive isEqualToString:@"false"]) || ![destructive boolValue]) {
        myAction.destructive = NO;
    } else {
        myAction.destructive = YES;
    }
    myAction.authenticationRequired = NO;
    
    return myAction;
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (self.callbackId == nil) {
        NSLog(@"Unexpected call to didRegisterForRemoteNotificationsWithDeviceToken, ignoring: %@", deviceToken);
        return;
    }
    NSLog(@"Push Plugin register success: %@", deviceToken);
    
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    NSString *token = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
                        stringByReplacingOccurrencesOfString:@">" withString:@""]
                       stringByReplacingOccurrencesOfString: @" " withString: @""];
    [results setValue:token forKey:@"deviceToken"];
    
    // Get Bundle Info for Remote Registration (handy if you have more than one app)
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"] forKey:@"appName"];
    [results setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
    
    // Check what Notifications the user has turned on.  We registered for all three, but they may have manually disabled some or all of them.
    NSUInteger rntypes = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];

    // Set the defaults to disabled unless we find otherwise...
    NSString *pushBadge = @"disabled";
    NSString *pushAlert = @"disabled";
    NSString *pushSound = @"disabled";
    
    // Check what Registered Types are turned on. This is a bit tricky since if two are enabled, and one is off, it will return a number 2... not telling you which
    // one is actually disabled. So we are literally checking to see if rnTypes matches what is turned on, instead of by number. The "tricky" part is that the
    // single notification types will only match if they are the ONLY one enabled.  Likewise, when we are checking for a pair of notifications, it will only be
    // true if those two notifications are on.  This is why the code is written this way
    if(rntypes & UIRemoteNotificationTypeBadge){
        pushBadge = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeAlert) {
        pushAlert = @"enabled";
    }
    if(rntypes & UIRemoteNotificationTypeSound) {
        pushSound = @"enabled";
    }
    
    [results setValue:pushBadge forKey:@"pushBadge"];
    [results setValue:pushAlert forKey:@"pushAlert"];
    [results setValue:pushSound forKey:@"pushSound"];
    
    // Get the users Device Model, Display Name, Token & Version Number
    UIDevice *dev = [UIDevice currentDevice];
    [results setValue:dev.name forKey:@"deviceName"];
    [results setValue:dev.model forKey:@"deviceModel"];
    [results setValue:dev.systemVersion forKey:@"deviceSystemVersion"];
    
    if(![self usesFCM]) {
        [self registerWithToken: token];
    }
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (self.callbackId == nil) {
        NSLog(@"Unexpected call to didFailToRegisterForRemoteNotificationsWithError, ignoring: %@", error);
        return;
    }
    NSLog(@"Push Plugin register failed");
    [self failWithMessage:self.callbackId withMsg:@"" withError:error];
}

- (void)notificationReceived {
    NSLog(@"Notification received");
    
    if (_notificationMessage && self.callbackId != nil) {
        NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:4];
        NSMutableDictionary* additionalData = [NSMutableDictionary dictionaryWithCapacity:4];
        
        
        for (id key in _notificationMessage) {
            if ([key isEqualToString:@"aps"]) {
                id aps = [_notificationMessage objectForKey:@"aps"];
                
                for(id key in aps) {
                    NSLog(@"Push Plugin key: %@", key);
                    id value = [aps objectForKey:key];
                    
                    if ([key isEqualToString:@"alert"]) {
                        if ([value isKindOfClass:[NSDictionary class]]) {
                            for (id messageKey in value) {
                                id messageValue = [value objectForKey:messageKey];
                                if ([messageKey isEqualToString:@"body"]) {
                                    [message setObject:messageValue forKey:@"message"];
                                } else if ([messageKey isEqualToString:@"title"]) {
                                    [message setObject:messageValue forKey:@"title"];
                                } else {
                                    [additionalData setObject:messageValue forKey:messageKey];
                                }
                            }
                        }
                        else {
                            [message setObject:value forKey:@"message"];
                        }
                    } else if ([key isEqualToString:@"title"]) {
                        [message setObject:value forKey:@"title"];
                    } else if ([key isEqualToString:@"badge"]) {
                        [message setObject:value forKey:@"count"];
                    } else if ([key isEqualToString:@"sound"]) {
                        [message setObject:value forKey:@"sound"];
                    } else if ([key isEqualToString:@"image"]) {
                        [message setObject:value forKey:@"image"];
                    } else {
                        [additionalData setObject:value forKey:key];
                    }
                }
            } else {
                [additionalData setObject:[_notificationMessage objectForKey:key] forKey:key];
            }
        }
        
        if (_isInline) {
            [additionalData setObject:[NSNumber numberWithBool:YES] forKey:@"foreground"];
        } else {
            [additionalData setObject:[NSNumber numberWithBool:NO] forKey:@"foreground"];
        }
        
        if (_coldstart) {
            [additionalData setObject:[NSNumber numberWithBool:YES] forKey:@"coldstart"];
        } else {
            [additionalData setObject:[NSNumber numberWithBool:NO] forKey:@"coldstart"];
        }
        
        [message setObject:additionalData forKey:@"additionalData"];
        
        // send notification message
        self.coldstart = NO;
        self.notificationMessage = nil;
    }
}

- (void)setApplicationIconBadgeNumber:(NSMutableDictionary*) options {
    int badge = [[options objectForKey:@"badge"] intValue] ?: 0;
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    
    NSString* message = [NSString stringWithFormat:@"app badge count set to %d", badge];
}

- (void)getApplicationIconBadgeNumber {
    NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
}

- (void)clearAllNotifications {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    NSString* message = [NSString stringWithFormat:@"cleared all notifications"];
}

- (void)hasPermission {
    BOOL enabled = NO;
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    enabled = [appDelegate performSelector:@selector(userHasRemoteNotificationsEnabled)];

    NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:1];
    [message setObject:[NSNumber numberWithBool:enabled] forKey:@"isEnabled"];
}

-(void)successWithMessage:(NSString*)message{

}

-(void)registerWithToken:(NSString*)token {
    // Send result to trigger 'registration' event but keep callback
    NSMutableDictionary* message = [NSMutableDictionary dictionaryWithCapacity:1];
    [message setObject:token forKey:@"registrationId"];
}


-(void)failWithMessage:(NSString *)callbackId withMsg:(NSString *)message withError:(NSError *)error {
    NSString *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
}

-(void) finish:(NSString*)notId{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.1
                                         target:self
                                       selector:@selector(stopBackgroundTask:)
                                       userInfo:notId
                                        repeats:NO];
    });
}

-(void)stopBackgroundTask:(NSTimer*)timer {
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    
    NSLog(@"Push Plugin stopBackgroundTask called");
    
    if (_handlerObj) {
        NSLog(@"Push Plugin handlerObj");
        id userInfo = [timer userInfo];
        completionHandler = [_handlerObj[userInfo] copy];
        if (completionHandler) {
            NSLog(@"Push Plugin: stopBackgroundTask (remaining t: %f)", sharedApplication.backgroundTimeRemaining);
            completionHandler(UIBackgroundFetchResultNewData);
            completionHandler = nil;
        }
    }
}

@end
