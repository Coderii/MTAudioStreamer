//
//  MTAudioDownloadProvider.m
//  Pods
//
//  Created by Cheng on 16/7/28.
//
//

#import "MTAudioDownloadProvider.h"
#include <CommonCrypto/CommonDigest.h>
#import "NSData+DOUMappedFile.h"
#import "MTAudioHTTPRequest.h"
#import "NSString+MTSH256Path.h"
 
@interface MTAudioDownloadProvider() {
    NSURL *_audioFileURL;
    NSString *_audioFileHost;
    NSURL *_cachedURL;
    
    CC_SHA256_CTX *_sha256Ctx;
    NSString *_sha256;
    
    BOOL _failed;
    BOOL _requestCompleted;
    
    NSData *_mappedData;
    NSUInteger *_receivedLength;
    
    NSInteger _hasWriteSize;
}

@property (nonatomic, strong) NSFileHandle *disguiseFile;
@end

@implementation MTAudioDownloadProvider

#pragma mark - Life Cycle

- (void)dealloc {
    @synchronized(_request) {
        [_request setCompletedBlock:NULL];
        [_request setProgressBlock:NULL];
        [_request setDidReceiveResponseBlock:NULL];
        [_request cancel];
    }
    
    if (_sha256Ctx != NULL) {
        free(_sha256Ctx);
    }
}

- (instancetype)initAudioDownloadProviderWithAudioFile:(id<DOUAudioFile>)audioFile {
    if (self = [super init]) {
        _audioFileURL = [audioFile audioFileURL];
        if ([audioFile respondsToSelector:@selector(audioFileHost)]) {
            _audioFileHost = [audioFile audioFileHost];
        }
        [self createRequest];
    }
    return self;
}

- (void)createRequest {
    _request = [MTAudioHTTPRequest requestWithURL:_audioFileURL];
    if (_audioFileHost != nil) {
        [_request setHost:_audioFileHost];
    }
}

- (void)start {
    //开始请求
    [_request start];
     
    //接收到数据请求
    __weak typeof(self) _weakSelf = self;
    [_request setDidReceiveResponseBlock:^(void) {
        [_weakSelf requestDidReceiveResponse];
    }]; 
    
    //回调进度
    [_request setProgressBlock:^(double downloadProgress) {
        if (_weakSelf.providerProgress) {
            _weakSelf.providerProgress(downloadProgress);
        }
    }];

    //接收数据
    [_request setDidReceiveDataBlock:^(NSData *data) {
        [_weakSelf requestDidReceiveData:data];
    }];
    
    //缓存结束
    [_request setCompletedBlock:^(void) {
        [_weakSelf requestDidComplete];
        if (_weakSelf.providerCompleted) {
            _weakSelf.providerCompleted();
        }
    }];
}

- (void)cancel {
    [_request cancel];
    _canceled = YES;
}

- (void)pause {
    [_request pause];
    _paused = YES;
}

- (void)requestDidComplete {
    if ([_request isFailed] || !([_request statusCode] >= 200 && [_request statusCode] < 300)) {
        _failed = YES;
    }
    else {
        _requestCompleted = YES;
    }
    
    if (!_failed &&  _sha256Ctx != NULL) {
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(hash, _sha256Ctx);
        
        NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
        for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
            [result appendFormat:@"%02x", hash[i]];
        }
        _sha256 = [result copy];
    }
    
    // close disduiseFile and clear file
    [self.disguiseFile closeFile];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString mt_getDisguiseFileWithUrl:_audioFileURL] error:nil];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"request"];
    [userDefaults synchronize];
}

//设置请求返回的一些信息
- (void)requestDidReceiveResponse {
    //获取sha之后的缓存路径
    _cachedPath = [NSString mt_getRequestCachePathWithUrl:_audioFileURL];
    _cachedURL = [NSURL fileURLWithPath:_cachedPath];
}

- (void)requestDidReceiveData:(NSData *)data {
    [self.disguiseFile writeData:data];
    
    if (_sha256Ctx != NULL) {
        CC_SHA256_Update(_sha256Ctx, [data bytes], (CC_LONG)[data length]);
    }
}

//获取已经下载的文件大小
- (NSInteger)getCurrentSize {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[NSString mt_getRequestCachePathWithUrl:_audioFileURL]];
    if (fileHandle == nil) {
        return 0;
    }
    
    int fd = [fileHandle fileDescriptor];
    if (fd < 0) {
        return 0;
    }
    
    off_t size = lseek(fd, 0, SEEK_END);
    if (size < 0) {
        return 0;
    }
    return size;
}


#pragma mark -- Setter/Getter

- (NSFileHandle *)disguiseFile {
    if (!_disguiseFile) {
        [[NSFileManager defaultManager] createFileAtPath:[NSString mt_getDisguiseFileWithUrl:_audioFileURL]
                                                contents:nil
                                              attributes:nil];
        [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey: NSFileProtectionNone}
                                         ofItemAtPath:[NSString mt_getDisguiseFileWithUrl:_audioFileURL]
                                                error:NULL];
        [[NSFileHandle fileHandleForWritingAtPath:[NSString mt_getDisguiseFileWithUrl:_audioFileURL]] truncateFileAtOffset:[_request responseContentLength]];
        _disguiseFile = [NSFileHandle fileHandleForWritingAtPath:[NSString mt_getDisguiseFileWithUrl:_audioFileURL]];
    
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if (![userDefaults objectForKey:@"request"]) {  // 如果没有请求过
            [userDefaults setURL:_audioFileURL forKey:@"request"];
            [userDefaults synchronize];
        }
        else {
            NSString *getDataPath = [NSString mt_getRequestCachePathWithUrl:_audioFileURL];
            NSFileHandle *inFileHandle = [NSFileHandle fileHandleForReadingAtPath:getDataPath];
            NSData *inData = [inFileHandle availableData];
            
            [_disguiseFile writeData:inData];
        }
    }
    return _disguiseFile;
}
@end
