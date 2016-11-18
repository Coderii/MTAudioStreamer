//
//  MTOperation.m
//  MTDemo0729
//
//  Created by Cheng on 16/8/6.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTOperation.h"
#import "MTMusicFeature.h"

@implementation MTOperation {
@protected
    BOOL _finished;
    BOOL _executing;
    NSLock *_lock;
}
@end

#pragma mark - MTPlayMusicOperation

static MTPlayMusicOperation *playMusicOperation = nil;

@implementation MTPlayMusicOperation

- (instancetype)initPlayMusicOperationWith:(id<DOUAudioFile>)audioFile musicFeature:(MTMusicFeature *)musicFeaure {
    self = [super init];
    if (self) {
        _finished = NO;
        _executing = NO;
        _lock = [[NSLock alloc] init];
        
        self.audioFile = audioFile;
        self.musicFeature = musicFeaure;
        self.operationType = MTOperationTypePlay;
    }
    return self;
}

- (void)start {
    if (self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self performSelector:@selector(main) withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
    @try {
        if (self.isCancelled) return;
        [self startPlayMusic];
    } @catch (NSException *exception) {
        NSLog(@"Exception%@",exception);
    } @finally {
    }
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)cancel {
    [self willChangeValueForKey:@"isCancelled"];
    [super cancel];
    [self.musicFeature cancelWithType:MTMusicFeatureTypePlay];
    [self didChangeValueForKey:@"isCancelled"];
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)startPlayMusic {
    [_lock lock];
    [self.musicFeature startWithType:MTMusicFeatureTypePlay];
    
    if (self.isCancelled) {
        [self.musicFeature cancelWithType:MTMusicFeatureTypePlay];
        return;
    } 
    
    __weak typeof (self) _weakSelf = self;
    [self.musicFeature setPlayCacheProgress:^(double progress) {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        if (_strongSelf.operationProgress) {
            _strongSelf.operationProgress(progress);
        }
    }];
    
    [self.musicFeature setDownloadProgress:^(double progress) {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        if (_strongSelf.operationProgress) {
            _strongSelf.operationProgress(progress);
        }
    }];
    
    if (self.musicFeature.localFileExist) {
        if (self.operationProgress) {
            self.operationProgress(1.0f);
        }
    }
    
    [self.musicFeature setPlayCacheComplete:^() {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        [_strongSelf willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [_strongSelf didChangeValueForKey:@"isFinished"];
        
        [_strongSelf willChangeValueForKey:@"isExecuting"];
        _executing = NO;
        [_strongSelf didChangeValueForKey:@"isExecuting"];
    }];
    [_lock unlock];
}
@end

#pragma mark - MTDownloadOperation

@implementation MTDownloadOperation

- (instancetype)initDownloadOperationWith:(id<DOUAudioFile>)audioFile musicFeature:(MTMusicFeature *)musicFeaure {
    self = [super init];
    if (self) {
        _finished = NO;
        _executing = NO;
        _lock = [[NSLock alloc] init];
        
        self.musicFeature = musicFeaure;
        self.audioFile = audioFile;
        self.operationType = MTOperationTypeDownload;
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

    [self performSelector:@selector(main) withObject:nil];
  
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main {
    @try {
        if (self.isCancelled) return;
        [self startDownload];
    } @catch (NSException *exception) {
        NSLog(@"Exception%@",exception);
    } @finally {
    }
}

- (BOOL)isExecuting {
    return _executing;
}

- (BOOL)isFinished {
    return _finished;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)cancel {
    // cancelled
    [self willChangeValueForKey:@"isCancelled"];
    [super cancel];
    
    [self.musicFeature cancelWithType:MTMusicFeatureTypeDownload];
    
    [self didChangeValueForKey:@"isCancelled"];
    
    // finished executing
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark -- Class methods

- (void)startDownload {
    [_lock lock];
    NSLog(@"current thread = %@", [NSThread currentThread]);
    [self.musicFeature startWithType:MTMusicFeatureTypeDownload];
    
    if (self.isCancelled) {
        [self.musicFeature cancelWithType:MTMusicFeatureTypeDownload];
        return;
    }
    
    __weak typeof (self) _weakSelf = self;
    [self.musicFeature setDownloadProgress:^(double progress) {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        if (_strongSelf.operationProgress) {
            _strongSelf.operationProgress(progress);
        }
    }];
    
    [self.musicFeature setPlayCacheProgress:^(double progress) {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        if (_strongSelf.operationProgress) {
            _strongSelf.operationProgress(progress);
        }
    }];
    
    if (self.musicFeature.localFileExist) {
        if (self.operationProgress) {
            self.operationProgress(1.0f);
        }
    }
    
    [self.musicFeature setDownloadComplete:^() {
        __strong typeof(_weakSelf) _strongSelf = _weakSelf;
        [_strongSelf willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [_strongSelf didChangeValueForKey:@"isFinished"];
        
        [_strongSelf willChangeValueForKey:@"isExecuting"];
        _executing = NO;
        [_strongSelf didChangeValueForKey:@"isExecuting"];
    }];
    [_lock unlock];
} 
@end
