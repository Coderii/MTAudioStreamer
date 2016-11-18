//
//  MTMusicFeature.m
//  MTHTTPRequest
//
//  Created by Cheng on 16/7/28.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTMusicFeature.h"
#import "DOUAudioStreamer.h"
#import "MTAudioDownloadProvider.h"
#import "NSString+MTSH256Path.h"

#define MT_EPSION 0.000001

static NSString * const kMT_downloadKey = @"download";
static NSString * const kMT_playKey = @"play";
static NSString * const kMT_bufferingRatio = @"bufferingRatio";

#pragma mark - MTMusicFeatureTrack

@interface MTMusicFeatureTrack : NSObject<DOUAudioFile>
@property (nonatomic, strong) NSURL *audioFileURL;
@end

@implementation MTMusicFeatureTrack
@end

#pragma mark - MTMusicFeature 

static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;
static void *kProgress = &kProgress;

@interface MTMusicFeature() {
    id<DOUAudioFile> _audioFile;    //audiofile
    BOOL _hasObserver;
}

@property (nonatomic, strong) MTAudioDownloadProvider *downloadProvider;
@property (nonatomic, assign) BOOL urlHasPlay;
@property (nonatomic, assign) BOOL urlHasDownload;

@property (nonatomic, strong) NSDictionary *playUrlDict;
@property (nonatomic, strong) NSDictionary *downloadUrlDict;
@property (nonatomic, copy) NSString *localFilePath;

@end

@implementation MTMusicFeature

#pragma mark -- LifeCycle

- (void)dealloc {
    NSLog(@"MTMusicFeature dealloc");
    _downloadUrlDict = nil;
    _playUrlDict = nil;

    [self removeObserver];
    
    [self.downloadProvider cancel];
    self.downloadProvider = nil;
}

- (instancetype)initMusicFeatureWithAudioFile:(id<DOUAudioFile>)audioFile {
    if (self = [super init]) {
        _audioFile = audioFile;
        _urlHasDownload = NO;
        _urlHasPlay = NO;
    }
    return self;
}

#pragma mark -- ClassMethods

- (void)startWithType:(MTMusicFeatureType)type {
    switch (type) {
        case MTMusicFeatureTypePlay: {
            [self playMusic];
            break;
        }
        case MTMusicFeatureTypeDownload: {
            [self downloadMusic];
            break;
        }
    }
}

- (void)playMusic {
    [self removeObserver];
    
    if ([[_audioFile audioFileURL] isEqual:[self.downloadUrlDict objectForKey:kMT_downloadKey]] // if this url has download first
        || [self documentHasTheUrlFile]) {  // restart the app if this url downloaded complete

        MTMusicFeatureTrack *track = [[MTMusicFeatureTrack alloc] init];

        if ([self documentHasTheUrlFile]) { // restart the app if this url downloaded complete, play cache file direct
            
            // if dire play (self.downloadProvider.cachedPath is nil) get cachePath direct
            track.audioFileURL = [NSURL fileURLWithPath:[[NSString mt_getFileDocumentPath] stringByAppendingPathComponent:self.localFilePath]];
            self.streamer = [DOUAudioStreamer streamerWithAudioFile:track];
            
            _localFileExist = YES;
        }
        else {
            if (self.downloadProvider.canceled || self.downloadProvider.paused) {
                [self.downloadProvider start];
            }
        
            // feedback the cache progress
            __weak typeof(self) _weakSelf = self;
            [self.downloadProvider setProviderProgress:^(double progress) {
                if (_weakSelf.playCacheProgress) {
                    _weakSelf.playCacheProgress(progress);
                }

                // save file when download finished
                if (fabs(progress - 1.0) <= MT_EPSION) {
                    [_weakSelf saveFileToDocument];
                }
            }];
            
            // play the DisguiseFile
            track.audioFileURL = [NSURL fileURLWithPath:[NSString mt_getDisguiseFileWithUrl:[_audioFile audioFileURL]]];
            self.streamer = [DOUAudioStreamer streamerWithAudioFile:track];
        }
    }
    else {
        // play the music with request url,if request without finished,
        // but cache a little ,so next time request first and play after this request
        NSString *cachePath = [NSString mt_getRequestCachePathWithUrl:[_audioFile audioFileURL]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            self.downloadProvider = [[MTAudioDownloadProvider alloc] initAudioDownloadProviderWithAudioFile:_audioFile];
            [self.downloadProvider start];
            
            __weak typeof(self) _weakSelf = self;
            [self.downloadProvider setProviderProgress:^(double progress) {
                if (_weakSelf.downloadProgress) {
                    _weakSelf.downloadProgress(progress);
                }
            }];
            
            MTMusicFeatureTrack *track = [[MTMusicFeatureTrack alloc] init];
            track.audioFileURL = [NSURL fileURLWithPath:cachePath];
            self.streamer = [DOUAudioStreamer streamerWithAudioFile:track];
        }
        else {
            //play the music with request url
            self.streamer = [DOUAudioStreamer streamerWithAudioFile:_audioFile];
            
            //add observer only online play
            [self.streamer addObserver:self forKeyPath:kMT_bufferingRatio options:NSKeyValueObservingOptionNew context:kBufferingRatioKVOKey];
            _hasObserver = YES;
        }
    }
    // play
    [self.streamer play];
    
    // url status
    _urlHasPlay = YES;
    
    //save info
    self.playUrlDict = @{kMT_playKey: [_audioFile audioFileURL]};
}

- (void)downloadMusic {
    if ([[_audioFile audioFileURL] isEqual:[self.playUrlDict objectForKey:kMT_playKey]] // if this url has play first or Cache complete
        || [self documentHasTheUrlFile]) {  // the url have a local file
        
        // if documentHasTheUrlFile, it must have a local file
        if ([self documentHasTheUrlFile]) {
            _localFileExist = YES;
        }
        else {
            self.playUrlDict = nil;
            [self downloadMusic];
        }
    }
    else {  // a new url need download
        self.downloadProvider = [[MTAudioDownloadProvider alloc] initAudioDownloadProviderWithAudioFile:_audioFile];
        [self.downloadProvider start];
        
        __weak typeof(self) _weakSelf = self;
        [self.downloadProvider setProviderProgress:^(double progress) {
            if (_weakSelf.downloadProgress) {
                _weakSelf.downloadProgress(progress);
            }
            
            // save file when download finished
            if (fabs(progress - 1.0) <= MT_EPSION) {
                [_weakSelf saveFileToDocument];
                
                // block
                if (_weakSelf.downloadComplete) {
                    _weakSelf.downloadComplete();
                }
            }
        }];
    }
    // url status
    _urlHasDownload = YES;
    
    // save info
    self.downloadUrlDict = @{kMT_downloadKey: [_audioFile audioFileURL]};
}

- (void)updateBufferingStatus {
    if (_urlHasPlay) {
        if (_downloadProgress) {
            _downloadProgress(self.streamer.bufferingRatio);
        }
    }
    
    // play music without download first
    if (_urlHasDownload) {
        if (_playCacheProgress) {
            _playCacheProgress(self.streamer.bufferingRatio);
        }
    }
    
    // save file when cache online finished
    if (fabs(self.streamer.bufferingRatio - 1.0) <= MT_EPSION) {
        [self saveFileToDocument];
        if (_playCacheComplete) {
            _playCacheComplete();
        }
    }
}

- (void)pauseWithType:(MTMusicFeatureType)type {
    switch (type) {
        case MTMusicFeatureTypePlay: {
            [self.streamer pause];
            break;
        }
        case MTMusicFeatureTypeDownload: {
            [self.downloadProvider pause];
            break;
        }
    }
}

- (void)cancelWithType:(MTMusicFeatureType)type {
    switch (type) {
        case MTMusicFeatureTypePlay: {
            [self.streamer stop];
            break;
        }
        case MTMusicFeatureTypeDownload: {
            [self.downloadProvider cancel];
            break; 
        }
    }
}

// save file when progress = 100% 
- (void)saveFileToDocument {
    NSString *oriPath = [NSString mt_getRequestCachePathWithUrl:[_audioFile audioFileURL]];
    NSString *fileName = [NSString mt_sha256ForAudioFileURL:[_audioFile audioFileURL]];
    NSString *desPath = [[NSString mt_getFileDocumentPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", fileName, [NSString mt_getPathExtensionWithURL:[_audioFile audioFileURL]]]];
    
    [[NSFileManager defaultManager] moveItemAtPath:oriPath toPath:desPath error:nil];
}

// reture the BOOL the document has/has't This AudioFile
- (BOOL)documentHasTheUrlFile {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[NSString mt_getFileDocumentPath] stringByAppendingPathComponent:self.localFilePath]];
}

- (void)clearFileWithAudioFile:(id<DOUAudioFile>)audioFile {
    [[NSFileManager defaultManager] removeItemAtPath:[[NSString mt_getFileDocumentPath] stringByAppendingPathComponent:self.localFilePath] error:nil];
}

- (void)removeObserver {
    if (_hasObserver) {
        [self.streamer removeObserver:self forKeyPath:kMT_bufferingRatio];
        _hasObserver = NO;
    }
}

#pragma mark -- Observer

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == kBufferingRatioKVOKey) {
        [self performSelector:@selector(updateBufferingStatus)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
    }
}

#pragma mark -- Setter/Getter

- (NSDictionary *)playUrlDict {
    if (!_playUrlDict) {
        _playUrlDict = [NSDictionary dictionary];
    }
    return _playUrlDict;
}

- (NSDictionary *)downloadUrlDict {
    if (!_downloadUrlDict) {
        _downloadUrlDict = [[NSDictionary alloc] init];
    }
    return _downloadUrlDict;
}

- (NSString *)localFilePath {
    if (!_localFilePath || _localFilePath.length == 0) {
        _localFilePath = [NSString stringWithFormat:@"%@.%@", [NSString mt_sha256ForAudioFileURL:[_audioFile audioFileURL]], [NSString mt_getPathExtensionWithURL:[_audioFile audioFileURL]]];
    }
    return _localFilePath;
}
@end
