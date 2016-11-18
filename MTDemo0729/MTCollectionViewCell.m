//
//  MTCollectionViewCell.m
//  MTMusicDemo
//
//  Created by Cheng on 16/7/22.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTCollectionViewCell.h"
#import "MTConstant.h"
#import "Track.h"
#import "UIImageView+WebCache.h"

static void *kProgress = &kProgress;

@interface MTCollectionViewCell() {
    
}

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *downButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, assign, getter=isMusicPlaying) BOOL musicPlaying;
@end

@implementation MTCollectionViewCell

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"init");
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = [UIColor purpleColor];
    
    //imageview
    self.imageView.frame = self.contentView.bounds;
    
    //downButton
    CGFloat downButtonX = self.contentView.bounds.size.width - MT_DOWNLOADBUTTONW - MT_MARGIN;
    CGFloat downButtonY = self.contentView.bounds.size.height - MT_DOWNLOADBUTTONW - MT_MARGIN;
    self.downButton.frame = CGRectMake(downButtonX, downButtonY, MT_DOWNLOADBUTTONW, MT_DOWNLOADBUTTONW);
    
    //deleteButton
    CGFloat deleteButtonX = MT_MARGIN;
    CGFloat deleteButtonY = self.contentView.bounds.size.height - MT_DOWNLOADBUTTONW - MT_MARGIN;
    self.deleteButton.frame = CGRectMake(deleteButtonX, deleteButtonY, MT_DOWNLOADBUTTONW, MT_DOWNLOADBUTTONW);
    
    //progressView
    CGFloat progressViewW = self.bounds.size.width - 2 * MT_PROGRESSVIEW_MARGIN;
    CGFloat progressViewH = 2.0f;
    CGFloat progressViewX = MT_PROGRESSVIEW_MARGIN;
    CGFloat progressViewY = MT_MARGIN * 2;
    self.cacheProgressView.frame = CGRectMake(progressViewX, progressViewY, progressViewW, progressViewH);
}

#pragma mark - ClassMethods

- (void)downButtonClick:(UIButton *)button {
    //hide
    [button setHidden:YES];
    [self.deleteButton setHidden:YES];
    
    //添加progress
    CGFloat progressViewW = self.bounds.size.width - 2 * MT_PROGRESSVIEW_MARGIN;
    CGFloat progressViewH = 2.0f;
    CGFloat progressViewX = MT_PROGRESSVIEW_MARGIN;
    CGFloat progressViewY = self.bounds.size.height - progressViewH - MT_MARGIN * 2;
    
    [self.downloadProgressView removeObserver:self forKeyPath:@"progress"];
    self.downloadProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(progressViewX, progressViewY, progressViewW, progressViewH)];
    self.downloadProgressView.trackTintColor = [UIColor whiteColor];
    self.downloadProgressView.tintColor = [UIColor colorWithRed:247.0 / 255.0f green:78.0 / 255.0f blue:120.0 / 255.0f alpha:1.0f];
    [self.downloadProgressView addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:kProgress];
    
    [self.contentView addSubview:self.downloadProgressView];
    
    //show deleteButton
    if (fabs(self.downloadProgressView.progress - 1.0) <= MT_EPSILON) {
        [self.deleteButton setHidden:NO];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(collectionViewCellDownload:deleteButton:trakModel:)]) {
        [_delegate collectionViewCellDownload:self deleteButton:self.deleteButton trakModel:_track];
    }
}

- (void)deleteButtonClick:(UIButton *)button { 
    [self.downButton setHidden:NO];
    
    if (_delegate && [_delegate respondsToSelector:@selector(collectionViewCellDeleteClickTrackModel:)]) {
        [_delegate collectionViewCellDeleteClickTrackModel:_track];
    }
    
}

- (void)updateProgress {
    //比较大小
    if (fabs(self.downloadProgressView.progress - 1.0) <= MT_EPSILON) {
        [self.deleteButton setHidden:NO];
        [self.downloadProgressView removeFromSuperview];
    }
}

#pragma mark -- Observer

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == kProgress) {
        [self performSelector:@selector(updateProgress)
                     onThread:[NSThread mainThread]
                   withObject:nil
                waitUntilDone:NO];
    }
}

#pragma mark - Setter/Getter

- (void)setHasDownloadButton:(BOOL)hasDownloadButton {
    _hasDownloadButton = hasDownloadButton;
    if (_hasDownloadButton) {
        [self.downButton setHidden:YES];
    }
}

- (void)setTrack:(Track *)track {
    _track = track;
    
    //set imageView
    [self.imageView sd_setImageWithURL:track.imageUrl];
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_imageView];
    }
    return _imageView;
}

- (UIButton *)downButton {
    if (!_downButton) {
        _downButton = [[UIButton alloc] init];
        _downButton.layer.cornerRadius = MT_DOWNLOADBUTTONW * 0.5;
        _downButton.layer.masksToBounds = YES;
        _downButton.backgroundColor = [UIColor colorWithRed:247.0 / 255.0f green:78.0 / 255.0f blue:120.0 / 255.0f alpha:1.0f];
        _downButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [_downButton setImage:[UIImage imageNamed:@"downLoad"] forState:UIControlStateNormal];
        [_downButton addTarget:self action:@selector(downButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_downButton];
    }
    return _downButton;
}

- (UIButton *)deleteButton {
    if (!_deleteButton) {
        _deleteButton = [[UIButton alloc] init];
        _deleteButton.layer.cornerRadius = MT_DOWNLOADBUTTONW * 0.5;
        _deleteButton.layer.masksToBounds = YES;
        _deleteButton.backgroundColor = [UIColor colorWithRed:247.0 / 255.0f green:78.0 / 255.0f blue:120.0 / 255.0f alpha:1.0f];
        _deleteButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
        [_deleteButton setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_deleteButton];
    }
    return _deleteButton;
}

- (UIProgressView *)cacheProgressView {
    if (!_cacheProgressView) {
        _cacheProgressView = [[UIProgressView alloc] init];
        _cacheProgressView.trackTintColor = [UIColor whiteColor];
        _cacheProgressView.tintColor = [UIColor colorWithRed:247.0 / 255.0f green:78.0 / 255.0f blue:120.0 / 255.0f alpha:1.0f];
//        [self.contentView addSubview:_cacheProgressView];
    }
    return _cacheProgressView;
}
@end

