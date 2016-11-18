//
//  MTMusicOperation.h
//  MTDemo0729
//
//  Created by Cheng on 16/8/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTOperationFileProtocol.h"

typedef void(^MTMusicOperationDownloadProgressFeadBackBlock)(double progress);

@class MTMusicFeature;
@interface MTMusicOperation : NSOperation

/**
 *  传入model和musicFeature初始化一个的operation
 *
 *  @param musicModel   传入的model
 *  @param musicFeature musicFeature
 *
 *  @return MTMusicOperation
 */
- (instancetype)initMusicOperationWithModel:(id<MTOperationFileProtocol>)musicModel musicFeature:(MTMusicFeature *)musicFeature;

@property (nonatomic, copy) MTMusicOperationDownloadProgressFeadBackBlock downLoadProgressFeadBackBlock;
@end
