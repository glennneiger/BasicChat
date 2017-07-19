//
//  AntiGravityEngineFCM.h
//  Chat
//
//  Created by Dan Park on 7/18/17.
//

#import <Foundation/Foundation.h>

@interface PushByFCM : NSObject
@property (nonatomic, copy) NSString *callbackId;
@property (nonatomic, copy) NSString *notificationCallbackId;
@property (nonatomic, copy) NSString *callback;

@property (nonatomic, strong) NSDictionary *notificationMessage;
@property BOOL isInline;
@property BOOL coldstart;
@property BOOL clearBadge;
@property (nonatomic, strong) NSMutableDictionary *handlerObj;

- (void)initRegistration;
- (void)unregister:(NSArray*)topics;
- (void)subscribe:(NSString*)topic;
- (void)unsubscribe:(NSString*)topic;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

- (void)setNotificationMessage:(NSDictionary *)notification;
- (void)notificationReceived;

- (void)willSendDataMessageWithID:(NSString *)messageID error:(NSError *)error;
- (void)didSendDataMessageWithID:(NSString *)messageID;
- (void)didDeleteMessagesOnServer;

// FCM Features
@property(nonatomic, assign) BOOL usesFCM;
@property(nonatomic, strong) NSNumber *fcmSandbox;
@property(nonatomic, strong) NSString *fcmSenderId;
@property(nonatomic, strong) NSDictionary *fcmRegistrationOptions;
@property(nonatomic, strong) NSString *fcmRegistrationToken;
@property(nonatomic, strong) NSArray *fcmTopics;

@end
