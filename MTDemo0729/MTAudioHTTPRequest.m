//
//  MTAudioHTTPRequest.m
//  Pods
//
//  Created by Cheng on 16/7/28.
//
//

#import "MTAudioHTTPRequest.h"
#import "NSString+MTSH256Path.h"

@interface MTAudioHTTPRequest() <NSURLSessionDataDelegate>{
    NSURL *_requestUrl;
    NSOutputStream *_stream;   //输出流
    NSInteger _totalSize;  //文件总大小
    NSInteger _currentSize;    //当前下载大小
    
    NSMutableData *_responseData;
    NSString *_responseString;
    NSDictionary *_responseHeaders;
    NSUInteger _responseContentLength;
    NSInteger _statusCode;
    NSString *_cachePath;
    
    CFAbsoluteTime _startedTime;
}

@property (nonatomic, strong) NSMutableURLRequest *request;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;   //下载任务
@end

@implementation MTAudioHTTPRequest

#pragma mark LifeCycle

- (void)dealloc {
    [self.session invalidateAndCancel];
}

+ (instancetype)requestWithURL:(NSURL *)url {
    if (url == nil) {
        return nil;
    }
    return [[self alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url {
    if (self = [super init]) {
        _requestUrl = url;
        _request = [NSMutableURLRequest requestWithURL:url];
        _userAgent = [[self class] defaultUserAgent];
        _timeoutInterval = [[self class] defaultTimeoutInterval];
        _request.timeoutInterval = _timeoutInterval;
    }
    return self;
}

#pragma mark ClassMethods

+ (NSTimeInterval)defaultTimeoutInterval {
    return MAXFLOAT;
}

+ (NSString *)defaultUserAgent {
    static NSString *defaultUserAgent = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [infoDict objectForKey:@"CFBundleName"];
        NSString *shortVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        NSString *bundleVersion = [infoDict objectForKey:@"CFBundleVersion"];
        
        NSString *deviceName = nil;
        NSString *systemName = nil;
        NSString *systemVersion = nil;
        
#if TARGET_OS_IPHONE
        UIDevice *device = [UIDevice currentDevice];
        deviceName = [device model];
        systemName = [device systemName];
        systemVersion = [device systemVersion];
#else /* TARGET_OS_IPHONE */
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        SInt32 versionMajor, versionMinor, versionBugFix;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);
        Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
#pragma clang diagnostic pop
        
        int mib[2] = { CTL_HW, HW_MODEL };
        size_t len = 0;
        sysctl(mib, 2, NULL, &len, NULL, 0);
        char *hw_model = malloc(len);
        sysctl(mib, 2, hw_model, &len, NULL, 0);
        deviceName = [NSString stringWithFormat:@"Macintosh %s", hw_model];
        free(hw_model);
        systemName = @"Mac OS X";
        systemVersion = [NSString stringWithFormat:@"%u.%u.%u", versionMajor, versionMinor, versionBugFix];
#endif /* TARGET_OS_IPHONE */
        
        NSString *locale = [[NSLocale currentLocale] localeIdentifier];
        defaultUserAgent = [NSString stringWithFormat:@"%@ %@ build %@ (%@; %@ %@; %@)", appName, shortVersion, bundleVersion, deviceName, systemName, systemVersion, locale];
    });
    
    return defaultUserAgent;
}

//开始任务
- (void)start {
    _startedTime = CFAbsoluteTimeGetCurrent();  //获取当前任务开始的时间
    _downloadSpeed = 0;
    [self.dataTask resume];
}

- (void)pause {
    [self.dataTask suspend];
}

- (void)cancel {
    [self.dataTask cancel];
}

//获取已经下载的文件大小
- (NSInteger)getCurrentSize {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:[NSString mt_getRequestCachePathWithUrl:_requestUrl]];
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

#pragma mark Delegate

//接收到服务器响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    //返回状态码
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
    _statusCode = httpResp.statusCode;
    _statusMessage = [NSHTTPURLResponse localizedStringForStatusCode:_statusCode];
    
    _totalSize = response.expectedContentLength + _currentSize;
    
    //写入streame
    _stream = [[NSOutputStream alloc] initToFileAtPath:[NSString mt_getRequestCachePathWithUrl:_requestUrl] append:YES];
    [_stream open];
    
    //return
    _responseContentLength = _totalSize;
    
    //接收服务器响应
    completionHandler(NSURLSessionResponseAllow);
    
    if (_didReceiveResponseBlock) {
        _didReceiveResponseBlock();
    }
}

//接收服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    //写入streame
    [_stream write:data.bytes maxLength:data.length];
    
    if (_didReceiveDataBlock) {
        _didReceiveDataBlock(data);
    }
    
    //appendData
    if (!_responseData) {
        _responseData = [NSMutableData data];
    }
    [_responseData appendData:data];
    
    _currentSize += data.length;
    
    //获取下载的速度
    _downloadSpeed = _currentSize / (CFAbsoluteTimeGetCurrent() - _startedTime);
    
    double progress = (double)_currentSize / _totalSize;
    if (_progressBlock) {
        _progressBlock(progress);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    //close streame
    [_stream close];
    _stream = nil;
    
    if (error) {
        _failed = YES;
    }
    else {
        if (_completedBlock) {
            _completedBlock();
        }
    }
}

#pragma mark Setter/Getter

- (NSURLSession *)session { 
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
 
- (NSURLSessionDataTask *)dataTask {
    if (!_dataTask) {
        _currentSize = [self getCurrentSize];
        
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", _currentSize];
        [_request setValue:range forHTTPHeaderField:@"Range"];
        
        //set host
        if (_host) {
            [_request setValue:_host forHTTPHeaderField:@"Host"];   //设置Host
        }
        
        //set User-Agent
        [_request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
        
        _dataTask = [self.session dataTaskWithRequest:_request];
    }
    return _dataTask;
}

- (NSUInteger)responseContentLength {
    return _totalSize;
}

- (NSString *)responseString {
    if (_responseData == nil) {
        return nil;
    }
    
    if (!_responseString) {
        _responseString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    }
    
    return _responseString;
}

- (NSDictionary *)responseHeaders {
    if (!_responseHeaders) {
        _responseHeaders = _request.allHTTPHeaderFields;
    }
    return _responseHeaders;
}

- (NSString *)cachePath {
    if (!_cachePath) {
        _cachePath = [NSString mt_getRequestCachePathWithUrl:_requestUrl];
    }
    return _cachePath;
}
@end
