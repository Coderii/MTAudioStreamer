//
//  MTMusicOperationManager.h
//  MTDemo0729
//
//  Created by Cheng on 16/8/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTOperationFileProtocol.h"

@class MTMusicFeature;
@interface MTMusicOperationManager : NSObject

/**
 *  Create a MTOperationQueueManager Singleton
 *
 *  @return MTOperationQueueManager
 */
+ (instancetype)sharedManager;

/**
 *  start a download operation with musicModel
 *
 *  @param musicModel   musicModel
 *  @param musicFeature musicFeature
 */
- (void)startDownloadWithMusicModel:(id<MTOperationFileProtocol>)musicModel musicFeature:(MTMusicFeature *)musicFeature;

/**
 *  start a play operation request, and feedback all download operations refresh new download progress
 *
 *  @param musicModel          a play model
 *  @param operation           play operation
 */
- (void)startPlayWithMusicModel:(id<MTOperationFileProtocol>)musicModel operation:(NSBlockOperation *)operation;

- (void)addMusicModels:(NSArray <MTOperationFileProtocol>*)musicModels;
- (void)stopWithMusicModel:(id<MTOperationFileProtocol>)musicModel;
@end
