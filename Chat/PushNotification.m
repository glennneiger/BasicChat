//
//  PushNotification.m
//  MessagingExample
//
//  Created by Dan Park on 7/6/17.
//  Copyright © 2017 Xtime Inc. All rights reserved.
//

#import "PushNotification.h"

@interface PushNotification () <NSURLSessionDataDelegate>
@property (nonnull, strong)  NSOperationQueue *queue;
@property (nonnull, strong)  NSURLSessionTask *task;
@end

@implementation PushNotification
static NSString *keyAPI = @"key=AAAATVUnThw:APA91bGKLISo7IHWL35MW-y9uWRhO0umdX-mzwmbfMZGZPoSQQVbMpi4ODRRymakW_Ih6g_UBx5rJic1Wz2a7acwEowlly8X3OGG7EIu9EUP_niXlOeEPOwExxFf2EXz6KFr1cSw4s5G";

+ (instancetype)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        NSOperationQueue *queue = [NSOperationQueue new];
        [queue setMaxConcurrentOperationCount:1];
        [self setQueue:queue];
    }
    return self;
}

- (NSNumber *)getTimeStampInPST
{
    NSDate* referenceDate = [NSDate dateWithTimeIntervalSince1970: 0];
    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"PST"];
    NSInteger offset = [timeZone secondsFromGMTForDate: referenceDate];
    NSTimeInterval unix_timestamp =  [[NSDate date] timeIntervalSince1970];
    NSTimeInterval Timestamp = unix_timestamp + offset;
    return [NSNumber numberWithInteger:(NSInteger)Timestamp];
}

+ (NSString *)registeredToken{
    NSString *registeredToken5X = @"fh8QdThR_II:APA91bELmkQtBwgSErJZY2xiXowzmNjRUEhmVCSojTEp11FRt5OpUg2_KddnpNFWKUIfUy5QOlcNuM4SHwweyS5-LEGmpkJ3pMEP8grKLATJcdo0jxzb_QoFaHrk326tQkv1Z_t-tSu9";
    NSString *registeredToken6Plus_cutecat = @"f39lDuofo-Q:APA91bET6j4wP-XwvNSqnxK5ckVooKZ4TCr_iEDnhm_hffiCvXDHwff08kV44U1W7bysOqJkGR4qFQJ4FOW-jpHzjvCCNnzvqOuhdxKusgGnlLqDFUNeyWZZcuj7rBp1y_H_V_dW3IAW";
    NSString *registeredToken6Plus_chatLocation = @"felq_rYwvIk:APA91bFewiztI6P_tM3gYSuZpllveVMzQtBhewUxBHCPPlhtkkZBdsCT_vNsO3GCGpqEGSxE416ZTgs2UWpHSI0QVMgY-jfopIX83NNTxX_L_7nAvD4qpDfFa1gS4eSodeyPj3NzhyIP";
    NSString *registeredToken6S_chatLocation = @"eMG-TKtKwec:APA91bG3zOoQ317X3RbrCLMkdsJLOfXN2WBvyQgtVL2P2DJ5piM9l4UyE6BF8ztS7ewoFwcgW08IGKDtsD_dEM5q-31H0lvZRLqi-31h5byx0tW4tTq_hgQDOw4NcNDiGVH7tOARsgGv";
    NSString *registeredToken6S_cutecat = @"efpXobEMQVE:APA91bFZFlbWj0k6MqJ-QscmuBzRlGrJM-Na8F70WMe2R4kJEi-6tUJSsJDFjt0HZo1RrWRdJoS9B2yVo_SG27ej4-pPqUXnk-GsC08x2rFAi-rxo1UYXeVA3ZHbt7Gb5zizZxI_vmwa";
    
    
    return registeredToken6S_cutecat;
}

+ (NSDictionary *)payload:(NSString *)message{
    NSDictionary *notification = @{
                                   @"body": message,
                                   @"priority": @10
                                   };
    return notification;
}

+ (NSDictionary *)notification{
    NSString *timestamp = [self timestampString];
    NSDictionary *notification = [self payload:timestamp];
    return notification;
}

+ (NSString *)timestampString {
    NSDateFormatter *formatter = [PushNotification formatter];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    return timestamp;
}

+ (NSDateFormatter *)formatter {
    static NSDateFormatter *formatter = nil;
    if (! formatter) {
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
    }
    return formatter;
}

+ (void)notifyToToken:(NSString *)token withMessage:(NSString *)message{
    
    NSURL *url = [NSURL URLWithString:@"https://fcm.googleapis.com/fcm/send"];
    NSTimeInterval timeoutInSeconds = 30;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeoutInSeconds];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:keyAPI forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    NSLog(@"%s: request:%@", __func__, request.allHTTPHeaderFields);
    
    NSDictionary *parameters = @{
                                 @"to": token,
                                 @"notification": [self payload:message],
                                 };
    NSLog(@"%s: parameters:%@", __func__, parameters);
    
    NSError *error = nil;
    NSData *jsonData = nil;
    if ([NSJSONSerialization isValidJSONObject:parameters]) {
        jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        [request setHTTPBody:jsonData];
    }
    
    PushNotification *logging = [self.class sharedInstance];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:logging delegateQueue:logging.queue];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                  {
                                      NSLog(@"%s: error:%@", __func__, error);
                                      NSLog(@"%s: response:%@", __func__, response);
                                      if (data.length > 0) {
                                          NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                          NSLog(@"%s: data.length:%lu", __func__, (unsigned long)data.length);
                                          NSLog(@"%s: data:%@", __func__, string);
                                      }
                                  }];
    
    [task resume];
}

+ (void)sendNotificatino:(NSString *)message{
    
    NSURL *url = [NSURL URLWithString:@"https://fcm.googleapis.com/fcm/send"];
    NSTimeInterval timeoutInSeconds = 30;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:timeoutInSeconds];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:keyAPI forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:@"POST"];
    NSLog(@"%s: request:%@", __func__, request.allHTTPHeaderFields);
    
    NSDictionary *parameters = @{
                                 @"to": [self.class registeredToken],
                                 @"notification": [self.class notification],
                                 };
    NSLog(@"%s: parameters:%@", __func__, parameters);

    NSError *error = nil;
    NSData *jsonData = nil;
    if ([NSJSONSerialization isValidJSONObject:parameters]) {
        jsonData = [NSJSONSerialization dataWithJSONObject:parameters
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
        [request setHTTPBody:jsonData];
    }
    
    PushNotification *logging = [self.class sharedInstance];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:logging delegateQueue:logging.queue];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        NSLog(@"%s: error:%@", __func__, error);
        NSLog(@"%s: response:%@", __func__, response);
        if (data.length > 0) {
            NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%s: data.length:%lu", __func__, (unsigned long)data.length);
            NSLog(@"%s: data:%@", __func__, string);
        }
    }];
    [logging setTask:task];
    [logging.task resume];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSLog(@"%s: response:%@", __func__, response);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    NSLog(@"%s: error:%@", __func__, error);
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    NSLog(@"%s: challenge:%@", __func__, challenge);
    
    NSURLCredential *credential = nil;
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        SecTrustResultType result;
        SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
        BOOL isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
        
        
        if (isValid) {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (credential) {
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    } else {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"%s: session:%@", __func__, session);
}

@end
