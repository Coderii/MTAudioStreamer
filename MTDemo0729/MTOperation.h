//
//  MTOperation.h
//  MTDemo0729
//
//  Created by Cheng on 16/8/6.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DOUAudioFile.h"

@class MTMusicFeature;

typedef NS_OPTIONS(NSUInteger, MTOperationType) {
    MTOperationTypePlay = 1 << 0,
    MTOperationTypeDownload = 1 << 1,
};

typedef void (^MTOperationComplertion)();
typedef void (^MTOperationProgress)(double progress);

/**
 *  MTOperation
 */
@interface MTOperation : NSOperation

@property (nonatomic, strong) MTMusicFeature *musicFeature;
@property (nonatomic, weak) id<DOUAudioFile> audioFile;
@property (nonatomic, assign) MTOperationType operationType;

@property (nonatomic, copy) MTOperationProgress operationProgress;
@end

/**
 *  MTPlayMusicOperation
 */
@interface MTPlayMusicOperation : MTOperation

- (instancetype)initPlayMusicOperationWith:(id<DOUAudioFile>)audioFile musicFeature:(MTMusicFeature *)musicFeaure;
@end

/**
 *  MTDownloadOperation
 */
@interface MTDownloadOperation : MTOperation

- (instancetype)initDownloadOperationWith:(id<DOUAudioFile>)audioFile musicFeature:(MTMusicFeature *)musicFeaure;
@end