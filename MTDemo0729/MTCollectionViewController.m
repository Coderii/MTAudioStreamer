//
//  MTCollectionViewController.m
//  MTMusicDemo
//
//  Created by Cheng on 16/7/22.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTCollectionViewController.h"
#import "MTCollectionViewCell.h"
#import "Track.h"
#import "MTMusicFeature.h"
#import "MTConstant.h"
#import "NSString+MTSH256Path.h"

#import "MTMusicOperationManager.h"
#import "MTMusicOperation.h"
//#import "MTOperationQueueManager.h"
//#import "MTASMusicOperation.h"

#import "MTOperationQueue.h"
#import "MTOperation.h"

@interface MTCollectionViewController()<MTCollectionViewCellDelegate> {
    NSMutableDictionary *_downModelCellDict;
    NSMutableDictionary *_musicFeatureModelDict; /** 一个model对应的一个Fearure **/
}
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *downLookButton;

@property (nonatomic, strong) NSArray *dataArray;

@property (nonatomic, strong) MTMusicFeature *musicFeature;
@property (nonatomic, strong) MTCollectionViewCell *currentCell;

@property (nonatomic, strong) MTOperationQueue *queue;

@property (nonatomic, strong) dispatch_queue_t downloadQueue;
@property (nonatomic, strong) dispatch_queue_t playQueue;

@property (nonatomic, strong) NSBlockOperation *operation;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation MTCollectionViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = self.titleLabel;
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.downLookButton];
    
    [self.collectionView registerClass:[MTCollectionViewCell class] forCellWithReuseIdentifier:@"MTCollectionViewCell"];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = 10.0f;
    CGFloat space = 5.0f;
    CGFloat width = (self.collectionView.bounds.size.width - 2 * space - 2 * margin) / 3;
    
    layout.sectionInset = UIEdgeInsetsMake(44, margin, 0, margin);
    layout.itemSize = CGSizeMake(width, width);
    layout.minimumLineSpacing = space;
    layout.minimumInteritemSpacing = space;
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView setCollectionViewLayout:layout];
    
    _downModelCellDict = [NSMutableDictionary dictionary];
    _musicFeatureModelDict = [NSMutableDictionary dictionary];
    
    _queue = [[MTOperationQueue alloc] init];
    _queue.maxConcurrentOperationCount = 3;
    
    _operationQueue = [NSOperationQueue new];
    _operationQueue.maxConcurrentOperationCount = 2;
    
    _downloadQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _playQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewCell *cell = (MTCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"MTCollectionViewCell" forIndexPath:indexPath];
    
    Track *track = [self.dataArray objectAtIndex:indexPath.item];
    
    cell.delegate = self;
    cell.track = track;
    
    // 需要设置一个model对应的一个musicFeature
    self.musicFeature = [[MTMusicFeature alloc] initMusicFeatureWithAudioFile:track];
    [_musicFeatureModelDict setObject:self.musicFeature forKey:[track audioFileURL].absoluteString];
    
    NSString *fileName =  [NSString stringWithFormat:@"%@.%@", [NSString mt_sha256ForAudioFileURL:[track audioFileURL]], [NSString mt_getPathExtensionWithURL:[track audioFileURL]]];
    BOOL hasDownloadButton = [[NSFileManager defaultManager] fileExistsAtPath:[[NSString mt_getFileDocumentPath] stringByAppendingPathComponent:fileName]];
    
    cell.hasDownloadButton = hasDownloadButton;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewCell *cell = (MTCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    Track *track = [_dataArray objectAtIndex:indexPath.item];
    MTMusicFeature *musicFeature = [_musicFeatureModelDict objectForKey:[track audioFileURL].absoluteString];
    dispatch_async(_playQueue, ^{
        [musicFeature startWithType:MTMusicFeatureTypePlay];
        
        [musicFeature setPlayCacheProgress:^(double progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.downloadProgressView.progress = progress;
            });
        }];
        
    });
    
#pragma mark - queue(unuse)
//    MTCollectionViewCell *cell = (MTCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
//    Track *track = [_dataArray objectAtIndex:indexPath.item];
//    MTMusicFeature *musicFeature = [_musicFeatureModelDict objectForKey:[track audioFileURL].absoluteString];
//    MTPlayMusicOperation *operation = [[MTPlayMusicOperation alloc] initPlayMusicOperationWith:track musicFeature:musicFeature];
//    
//    [operation setOperationProgress:^(double progress) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            cell.downloadProgressView.progress = progress;
//        });
//    }];
//    [self.queue addOperation:operation];
}

#pragma mark - Getter

- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [[NSArray alloc] init];
        
        NSURLRequest *dataRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://ob5w6r7cb.bkt.clouddn.com/music_list6.txt"]];
        
        NSData *data = [NSURLConnection sendSynchronousRequest:dataRequest
                                             returningResponse:NULL
                                                         error:NULL];
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        NSMutableArray *allTracks = [NSMutableArray array];
        for (NSDictionary *data in [dict objectForKey:@"data"]) {
            Track *track = [[Track alloc] init];
            track.audioFileURL = [NSURL URLWithString:[data objectForKey:@"music_url"]];
            track.imageUrl = [NSURL URLWithString:[data objectForKey:@"pic"]];
            [allTracks addObject:track];
        }
        _dataArray = allTracks;
    }
    return _dataArray;
}
 
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"选择音乐";
        _titleLabel.font = [UIFont systemFontOfSize:15.0];
        _titleLabel.textColor = [UIColor whiteColor];
        [_titleLabel sizeToFit];
    }
    return _titleLabel;
}

- (UIButton *)downLookButton { 
    if (!_downLookButton) {
        _downLookButton = [[UIButton alloc] init];
        _downLookButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_downLookButton setTitle:@"下载管理" forState:UIControlStateNormal];
        [_downLookButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_downLookButton addTarget:self action:@selector(downLoadListShow) forControlEvents:UIControlEventTouchUpInside];
        [_downLookButton sizeToFit];
    }
    return _downLookButton;
}

#pragma mark -- Class Methods

- (void)downLoadListShow {

}

#pragma mark -- Delegate

- (void)collectionViewCellDownload:(MTCollectionViewCell *)cell deleteButton:(UIButton *)button trakModel:(Track *)track {
    MTMusicFeature *musicFeature = [_musicFeatureModelDict objectForKey:track.audioFileURL.absoluteString];
    dispatch_async(_downloadQueue, ^{
        [musicFeature startWithType:MTMusicFeatureTypeDownload];
        [musicFeature setDownloadProgress:^(double progress) {
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.downloadProgressView.progress = progress;
            });
        }];
    });
    
#pragma mark - queue(unuse)
//    MTDownloadOperation *operation = [[MTDownloadOperation alloc] initDownloadOperationWith:track musicFeature:[_musicFeatureModelDict objectForKey:[track audioFileURL].absoluteString]];
//    
//    [operation setOperationProgress:^(double progress) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            cell.downloadProgressView.progress = progress;
//        });
//    }];
//    [self.queue addOperation:operation];
}

- (void)collectionViewCellDeleteClickTrackModel:(Track *)track {
    [[_musicFeatureModelDict objectForKey:[track audioFileURL].absoluteString] clearFileWithAudioFile:track];
    [[MTMusicOperationManager sharedManager] stopWithMusicModel:track];
}
@end
