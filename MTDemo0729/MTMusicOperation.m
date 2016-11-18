//
//  MTMusicOperation.m
//  MTDemo0729
//
//  Created by Cheng on 16/8/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTMusicOperation.h"
#import "MTMusicFeature.h"

@interface MTMusicOperation() {
    BOOL _finished;
    BOOL _executing;
}

@property (nonatomic, weak) id<DOUAudioFile> musicModel;
@property (nonatomic, strong) MTMusicFeature *musicFeature;
@end

@implementation MTMusicOperation

- (instancetype)initMusicOperationWithModel:(id<MTOperationFileProtocol>)musicModel musicFeature:(MTMusicFeature *)musicFeature {
    if (self = [super init]) {
        _finished = NO;
        _executing = NO;
        _musicModel = musicModel;
        _musicFeature = musicFeature;
    }
    return self;
}

- (void)start {
    if (self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main{
    @try {
        if (self.isCancelled) return;
        [self startRequest];
    } @catch (NSException *exception) {
        NSLog(@"Exception%@",exception);
    }
}

- (BOOL)isExecuting{
    return _executing;
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isConcurrent{
    return YES;
}

- (void)cancel{
    [self willChangeValueForKey:@"isCancelled"];
    [super cancel];
    [self.musicFeature cancelWithType:MTMusicFeatureTypeDownload];
    [self didChangeValueForKey:@"isCancelled"];
    [self completeOperation];
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)startRequest {
    [self.musicFeature startWithType:MTMusicFeatureTypeDownload];
    
    __weak typeof (self) _weakSelf = self;
    [self.musicFeature setDownloadProgress:^(double progress) {
        //block
        if (_weakSelf.downLoadProgressFeadBackBlock) {
            _weakSelf.downLoadProgressFeadBackBlock(progress);
        }
    }];
    
    [self.musicFeature setPlayCacheProgress:^(double progress) {
        if (_weakSelf.downLoadProgressFeadBackBlock) {
            _weakSelf.downLoadProgressFeadBackBlock(progress);
        }
    }];
    
    if (self.musicFeature.localFileExist) {
        if (self.downLoadProgressFeadBackBlock) {
            self.downLoadProgressFeadBackBlock(1.0f);
        }
    }
    
    if (self.isCancelled) {
        [self.musicFeature cancelWithType:MTMusicFeatureTypeDownload];
        return;
    }
    
    [self.musicFeature setDownloadComplete:^(void) {
        [_weakSelf willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [_weakSelf didChangeValueForKey:@"isFinished"];
        [_weakSelf willChangeValueForKey:@"isExecuting"];
        _executing = NO;
        [_weakSelf didChangeValueForKey:@"isExecuting"];
    }];
}
@end
