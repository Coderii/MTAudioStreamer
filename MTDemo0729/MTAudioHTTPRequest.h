//
//  MTAudioHTTPRequest.h
//  Pods
//
//  Created by Cheng on 16/7/28.
//
//
#import "UIKit/UIKit.h"
#import <Foundation/Foundation.h>

typedef void (^MTAudioHTTPRequestCompletedBlock)(void);
typedef void (^MTAudioHTTPRequestProgressBlock)(double progress);
typedef void (^MTAudioHTTPRequestDidReceiveResponseBlock)(void);
typedef void (^MTAudioHTTPRequestDidReceiveDataBlock)(NSData *data);

@interface MTAudioHTTPRequest : NSObject

/**
 *  init requst with a url
 *
 *  @param url request url
 *
 *  @return MTAudioHTTPRequest instance variable
 */
+ (instancetype)requestWithURL:(NSURL *)url;

/**
 *  init requst with a url
 *
 *  @param url request url
 *
 *  @return MTAudioHTTPRequest instance variable
 */
- (instancetype)initWithURL:(NSURL *)url;

/**
 *  defaultTimeoutInterval for request
 *
 *  @return NSTimeInterval
 */
+ (NSTimeInterval)defaultTimeoutInterval;

/**
 *  defaultUserAgent for this request
 *
 *  @return UserAgent
 */
+ (NSString *)defaultUserAgent;

@property (nonatomic, copy, readonly) NSString *cachePath;

@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSString *userAgent;
@property (nonatomic, strong) NSString *host;

@property (nonatomic, strong, readonly) NSData *responseData;
@property (nonatomic, copy, readonly) NSString *responseString;

@property (nonatomic, strong, readonly) NSDictionary *responseHeaders;
@property (nonatomic, assign, readonly) NSUInteger responseContentLength;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, copy, readonly) NSString *statusMessage;

/**
 *  start a MTAudioHTTPRequest
 */
- (void)start;

/**
 *  pause a MTAudioHTTPRequest
 */
- (void)pause;

/**
 *  cancel a MTAudioHTTPRequest
 */
- (void)cancel;

@property (nonatomic, readonly) NSUInteger downloadSpeed;
@property (nonatomic, readonly, getter=isFailed) BOOL failed;

@property (nonatomic, copy) MTAudioHTTPRequestCompletedBlock completedBlock;
@property (nonatomic, copy) MTAudioHTTPRequestProgressBlock progressBlock;
@property (nonatomic, copy) MTAudioHTTPRequestDidReceiveResponseBlock didReceiveResponseBlock;
@property (nonatomic, copy) MTAudioHTTPRequestDidReceiveDataBlock didReceiveDataBlock;

@end
