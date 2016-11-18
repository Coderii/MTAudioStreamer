//
//  MTOperationQueue.h
//  MTOperationQueue
//
//  Created by Cheng on 16/8/5.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MTOperation;
@interface MTOperationQueue : NSObject

- (void)addOperation:(MTOperation *)operation;

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;
@end
