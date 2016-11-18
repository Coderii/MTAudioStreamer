//
//  MTAudioDownloadProvider.h
//  Pods
//
//  Created by Cheng on 16/7/28.
//
//

#import <Foundation/Foundation.h>
#import "DOUAudioFile.h"

typedef void (^MTAudioDownloadProviderProgress)(double progress);
typedef void (^MTAudioDownloadProviderCompleted)();

@class MTAudioHTTPRequest;
@interface MTAudioDownloadProvider : NSObject

/**
 *  init a MTAudioDownloadProvider with a audioFile
 *
 *  @param a audioFile which inherit DOUAudioFile
 *
 *  @return MTAudioDownloadProvider
 */
- (instancetype)initAudioDownloadProviderWithAudioFile:(id<DOUAudioFile>)audioFile;

/**
 *  start DownloadProvider
 */
- (void)start;

/**
 *  pause DownloadProvider
 */
- (void)pause;

/**
 *  cancel DownloadProvider
 */
- (void)cancel;

@property (nonatomic, copy) MTAudioDownloadProviderProgress providerProgress;   /** DownloadProvider progress block **/
@property (nonatomic, copy) MTAudioDownloadProviderCompleted providerCompleted; /** DownloadProvider complete block **/

@property (nonatomic, strong) MTAudioHTTPRequest *request;
@property (nonatomic, copy) NSString *cachedPath;

@property (nonatomic, assign, readonly) BOOL canceled;
@property (nonatomic, assign, readonly) BOOL paused;

@end
