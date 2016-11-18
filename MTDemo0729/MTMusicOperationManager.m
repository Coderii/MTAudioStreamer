//
//  MTMusicOperationManager.m
//  MTDemo0729
//
//  Created by Cheng on 16/8/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTMusicOperationManager.h"
#import "MTMusicOperation.h"
#import "MTMusicFeature.h"

@interface MTMusicOperationManager() {
    NSMutableArray *_musicModels;
    NSMutableDictionary *_modelMusicFeatureDict;
}

@property (nonatomic ,strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSMutableArray *downOperationModel;
@end

@implementation MTMusicOperationManager
static MTMusicOperationManager *mt_musicOperationManager = nil;

+ (instancetype)sharedManager {
    static dispatch_once_t onceTaken;
    dispatch_once(&onceTaken, ^{
        mt_musicOperationManager = [[self alloc] init];
    });
    return mt_musicOperationManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _musicModels = [NSMutableArray array];
        _modelMusicFeatureDict = [NSMutableDictionary dictionary];
        _downOperationModel = [NSMutableArray array];
        _queue = [[NSOperationQueue alloc]init];
        _queue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (void)addMusicModels: (NSArray <MTOperationFileProtocol>*)musicModels {
    if ([musicModels isKindOfClass:[NSArray class]]) {
        [_musicModels addObjectsFromArray:musicModels];
    }
}

- (void)startDownloadWithMusicModel:(id<MTOperationFileProtocol>)musicModel musicFeature:(MTMusicFeature *)musicFeature {
    if (musicModel.operation == nil) {
        musicModel.operation = [[MTMusicOperation alloc] initMusicOperationWithModel:musicModel musicFeature:musicFeature];
    }
    if (musicModel.operation.isExecuting || musicModel.operation.isFinished) {
        
    }else{
        [_downOperationModel addObject:musicModel];
        
        // save info into _modelMusicFeatureDict
        [_modelMusicFeatureDict setObject:musicFeature forKey:[musicModel audioFileURL].absoluteString];
        
        [self.queue addOperation:musicModel.operation];
    }
}

- (void)startPlayWithMusicModel:(id<MTOperationFileProtocol>)musicModel operation:(NSBlockOperation *)operation {
    if (self.queue.operations.count < self.queue.maxConcurrentOperationCount) {
        [self.queue addOperation:operation];
        NSLog(@"====oldQueue");
    }
    else {
        [[NSOperationQueue new] addOperation:operation];
        NSLog(@"====newQueue");
    }
}

- (void)stopWithMusicModel:(id<MTOperationFileProtocol>)musicModel {
    if (musicModel.operation) {
        [musicModel.operation cancel];
        musicModel.operation = nil;
    }
}
@end
