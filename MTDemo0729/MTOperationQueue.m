//
//  MTOperationQueue.m
//  MTOperationQueue
//
//  Created by Cheng on 16/8/5.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTOperationQueue.h"
#import "MTOperation.h"

#pragma mark - MTOperationArrayObj

@protocol MTOperationArrayObjDelegate <NSObject>

@optional
- (void)operationArrayObjExecuteArrayAddSomeObj:(NSMutableArray *)executeArray;
- (void)operationArrayObjExecuteArrayRemoveSomeObj:(NSMutableArray *)executeArray;

- (void)operationArrayObjPlayMusicArrayAddSomeObj:(NSMutableArray *)playMusicArray;
- (void)operationArrayObjPlayMusicArrayRemoveSomeObj:(NSMutableArray *)playMusicArray;

- (void)operationArrayObjWaitingArrayAddSomeObj:(NSMutableArray *)waitingArray;
- (void)operationArrayObjWaitingArrayRemoveSomeObj:(NSMutableArray *)waitingArray;

@end

@interface MTOperationArrayObj : NSObject

@property (nonatomic, strong) NSMutableArray *executeArray;
@property (nonatomic, strong) NSMutableArray *waitingArray;
@property (nonatomic, strong) NSMutableArray *playMusicArray;

@property (nonatomic, weak) id<MTOperationArrayObjDelegate> delegate;
@end

@implementation MTOperationArrayObj

- (instancetype)init {
    self = [super init];
    if (self) {
        self.executeArray = [NSMutableArray array];
        self.waitingArray = [NSMutableArray array];
        self.playMusicArray = [NSMutableArray array];
    }
    return self;
}

- (void)insertObject:(NSObject *)object inExecuteArrayAtIndex:(NSUInteger)index {
    [self.executeArray insertObject:object atIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjExecuteArrayAddSomeObj:)]) {
        [_delegate operationArrayObjExecuteArrayAddSomeObj:self.executeArray];
    }
}

- (void)insertObject:(NSObject *)object inWaitingArrayAtIndex:(NSUInteger)index {
    [self.waitingArray insertObject:object atIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjWaitingArrayAddSomeObj:)]) {
        [_delegate operationArrayObjWaitingArrayAddSomeObj:self.waitingArray];
    }
}

- (void)insertObject:(NSObject *)object inPlayMusicArrayAtIndex:(NSUInteger)index {
    [self.playMusicArray insertObject:object atIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjPlayMusicArrayAddSomeObj:)]) {
        [_delegate operationArrayObjPlayMusicArrayAddSomeObj:self.playMusicArray];
    }
}

- (void)removeObjectFromExecuteArrayAtIndex:(NSUInteger)index {
    [self.executeArray removeObjectAtIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjExecuteArrayRemoveSomeObj:)]) {
        [_delegate operationArrayObjExecuteArrayRemoveSomeObj:self.executeArray];
    }
}

- (void)removeObjectFromWaitingArrayAtIndex:(NSUInteger)index {
    [self.waitingArray removeObjectAtIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjWaitingArrayRemoveSomeObj:)]) {
        [_delegate operationArrayObjWaitingArrayRemoveSomeObj:self.waitingArray];
    }
}

- (void)removeObjectFromPlayMusicArrayAtIndex:(NSUInteger)index {
    [self.playMusicArray removeObjectAtIndex:index];
    if (_delegate && [_delegate respondsToSelector:@selector(operationArrayObjPlayMusicArrayRemoveSomeObj:)]) {
        [_delegate operationArrayObjPlayMusicArrayRemoveSomeObj:self.playMusicArray];
    }
}

@end

#pragma mark - MTOperationQueue

@interface MTOperationQueue() <MTOperationArrayObjDelegate> {
    NSMutableDictionary *_threadDict;
    NSMutableDictionary *_playFirstDict;
}
@property (nonatomic, strong) MTOperationArrayObj *obj;
@end

@implementation MTOperationQueue

#pragma mark -- LifeCycle

- (void)dealloc {
    [_obj.executeArray removeAllObjects];
    [_obj.waitingArray removeAllObjects];
    
    _obj.executeArray = nil;
    _obj.waitingArray = nil;
    _obj = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _obj = [[MTOperationArrayObj alloc] init];
        _obj.delegate = self;
        
        _maxConcurrentOperationCount = 3;
        _threadDict = [NSMutableDictionary dictionary];
        _playFirstDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark -- ClassMethods

- (void)addOperation:(MTOperation *)operation {
    // 前面添加2个下载，后面一个直接拿去播放
    // 前面添加3个下载，后面一个model在等待队列，点击播放
    // 前面添加3个下载，后面一个model不在等待队列，点击播放
    // 重复添加播放进入队列导致，队列叠加。其实播放只有一个
    // 在运行中的队列只要点击过播放，或这下载，都不应该重新创建线程去做。
    switch (operation.operationType) {
        case MTOperationTypePlay: {
            [self playActon:operation];
            break;
        }
        case MTOperationTypeDownload: {
            [self downloadAction:operation];
            break;
        }
    }
}

- (void)playActon:(MTOperation *)operation {
    if (_obj.executeArray.count < _maxConcurrentOperationCount) {
        BOOL isInExecute = NO;
        for (MTOperation *inOp in _obj.executeArray) {
            if ([inOp.audioFile isEqual:operation.audioFile]) {
                isInExecute = YES;  // 表示点击的播放是正在下载的音乐
                break;
            }
        }

        if (isInExecute) {
            // 点击的播放是正在下载的音乐
            NSThread *thread = [_threadDict objectForKey:[operation.audioFile audioFileURL].absoluteString];
            [self performSelector:@selector(runPlayMusic:) onThread:thread withObject:operation waitUntilDone:NO];
        }
        else {
            // 点击的播放是没有在下载的音乐
            [[_obj mutableArrayValueForKey:@"playMusicArray"] addObject:operation];
            [_playFirstDict setObject:operation forKey:[operation.audioFile audioFileURL].absoluteString];
        }
    }
    else {
        // 超过并发数
        BOOL isInWaiting = NO;
        for (MTOperation *inOp in _obj.waitingArray) {
            if ([inOp.audioFile isEqual:operation.audioFile]) {
                isInWaiting = YES;  // 表示点击的是排在等待队列中的音乐
                break;
            }
        }
        
        if (isInWaiting) {
            // 点击的是排在等待队列中的音乐
        }
        else {
            // 点击的是没有排在等待队列中的音乐
        }
    }
}

// 下载肯定是进队列的
- (void)downloadAction:(MTOperation *)operation {
    
    // 下载一个已经点击播放的
    BOOL isInPlayArray = NO;
    for (MTOperation *inOP in _obj.playMusicArray) {
        if ([inOP.audioFile isEqual:operation.audioFile]) {
            isInPlayArray = YES;
            break;
        }
    }
    
    if (isInPlayArray) return;  // operation已经作为播放运行过直接return
    
    if (_obj.executeArray.count < _maxConcurrentOperationCount) {
        [[_obj mutableArrayValueForKey:@"executeArray"] addObject:operation];
    }
    else {
        [[_obj mutableArrayValueForKey:@"waitingArray"] addObject:operation];
    }
}

- (void)runDownloadMusic:(MTOperation *)operation {
    @autoreleasepool {
        [[NSRunLoop currentRunLoop] addPort:[NSPort new] forMode:NSRunLoopCommonModes];
        [operation start];
        [_threadDict setObject:[NSThread currentThread] forKey:[operation.audioFile audioFileURL].absoluteString];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)runPlayMusic:(MTOperation *)operation {
    [operation start];
}

#pragma mark -- Delegate 
#pragma mark executeArray

- (void)operationArrayObjExecuteArrayAddSomeObj:(NSMutableArray *)executeArray {
    MTOperation *operation = [executeArray objectAtIndex:executeArray.count - 1];
    
    // do operation
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runDownloadMusic:) object:operation];
    [thread start];
    
    // block
    __block typeof(operation) _blockOp = operation;
    __block typeof(NSMutableArray *) _blockArray = [_obj mutableArrayValueForKey:@"executeArray"];
    
    [operation setCompletionBlock:^ {
        [_blockArray removeObject:_blockOp];
    }];
}

- (void)operationArrayObjExecuteArrayRemoveSomeObj:(NSMutableArray *)executeArray {
    if (_obj.waitingArray.count != 0) {    //等待的队列中有operation才添加
        [self addOperation:[_obj.waitingArray firstObject]];
        [_obj.waitingArray removeObjectAtIndex:0];
    }
}

#pragma mark playMusicArray

- (void)operationArrayObjPlayMusicArrayAddSomeObj:(NSMutableArray *)playMusicArray {
    MTOperation *operation = [playMusicArray objectAtIndex:playMusicArray.count - 1];
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runPlayMusic:) object:operation];
    [thread start];
}
@end
