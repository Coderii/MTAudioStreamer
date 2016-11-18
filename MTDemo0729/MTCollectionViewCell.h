//
//  MTCollectionViewCell.h
//  MTMusicDemo
//
//  Created by Cheng on 16/7/22.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Track;
@class MTCollectionViewCell;
@protocol MTCollectionViewCellDelegate <NSObject>

@optional
- (void)collectionViewCellDownload:(MTCollectionViewCell *)cell deleteButton:(UIButton *)button trakModel:(Track *)track;
//- (void)collectionViewCellDownloadDeleteButton:(UIButton *)button progressView:(UIProgressView *)view trakModel:(Track *)track;
- (void)collectionViewCellDeleteClickTrackModel:(Track *)track;
@end

@interface MTCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) Track *track;
@property (nonatomic, weak) id<MTCollectionViewCellDelegate> delegate;

@property (nonatomic, strong) UIProgressView *downloadProgressView;
@property (nonatomic, strong) UIProgressView *cacheProgressView;

@property (nonatomic, assign) BOOL hasDownloadButton;
@end 
