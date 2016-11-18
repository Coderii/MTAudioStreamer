//
//  ViewController.m
//  MTDemo0729
//
//  Created by Cheng on 16/7/29.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "ViewController.h"
#import "Track.h"
#import "MTMusicFeature.h"

#define MTSCREEN_W [UIScreen mainScreen].bounds.size.width
#define MTSCREEN_H [UIScreen mainScreen].bounds.size.height

@interface ViewController () {
    Track *_track;
}

@property (nonatomic, assign) BOOL downBtnStatus;
@property (nonatomic, assign) BOOL playBtnStatus;

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;
@property (weak, nonatomic) IBOutlet UIProgressView *cacheProgressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

- (IBAction)downClick:(id)sender;
- (IBAction)playClick:(id)sender;
- (IBAction)clearClick:(id)sender;

@property (nonatomic, strong) MTMusicFeature *musicFeature;
@property (nonatomic, assign) BOOL flagCache;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"http://ob5w6r7cb.bkt.clouddn.com/%E9%B9%BF%E5%85%88%E6%A3%AE%E4%B9%90%E9%98%9F%20-%20%E6%98%A5%E9%A3%8E%E5%8D%81%E9%87%8C.mp3"];
    _track = [[Track alloc] init];
    _track.audioFileURL = url;
    self.musicFeature = [[MTMusicFeature alloc] initMusicFeatureWithAudioFile:_track];
}

- (IBAction)downClick:(id)sender {
    _downBtnStatus = !_downBtnStatus;
    _flagCache = YES;
    if (_downBtnStatus) {
        [_downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [self.musicFeature startWithType:MTMusicFeatureTypeDownload];
        
        __weak typeof(self) _weakSelf = self;
        [self.musicFeature setDownloadProgress:^(double progress) {
            _weakSelf.downloadProgressView.progress = progress;
        }];
        
        if (self.musicFeature.localFileExist) {
            self.downloadProgressView.progress = 1.0f;
        }
    }
    else {
        [_downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
        [self.musicFeature pauseWithType:MTMusicFeatureTypeDownload];
    }
}

- (IBAction)playClick:(id)sender {
    _playBtnStatus = !_playBtnStatus;
    if (_playBtnStatus) {
        [_playBtn setTitle:@"暂停" forState:UIControlStateNormal];
        [self.musicFeature startWithType:MTMusicFeatureTypePlay];
        
        __weak typeof(self) _weakSelf = self; 
        [self.musicFeature setPlayCacheProgress:^(double progress) {
            _weakSelf.cacheProgressView.progress = progress;
            
            if (_weakSelf.flagCache) {
                _weakSelf.downloadProgressView.progress = progress;
            }
        }];
        
        if (self.musicFeature.localFileExist) {
            self.cacheProgressView.progress = 1.0f;
        }
    }
    else {
        [_playBtn setTitle:@"播放" forState:UIControlStateNormal];
        [self.musicFeature pauseWithType:MTMusicFeatureTypePlay];
    }

}

- (IBAction)clearClick:(id)sender {
    [self.musicFeature clearFileWithAudioFile:_track];
}
@end
