//
//  MTMusicFeature.h
//  MTHTTPRequest
//
//  Created by Cheng on 16/7/28.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DOUAudioFile.h"

/**
 *   MTMusicFeature的类型
 */
typedef NS_OPTIONS(NSUInteger, MTMusicFeatureType) {
    MTMusicFeatureTypePlay = 1 << 0,    /**< 播放音乐 **/
    MTMusicFeatureTypeDownload = 1 << 1,    /**< 下载音乐 **/
};

typedef void (^MTMusicFeatureDownloadProgress)(double progress);
typedef void (^MTMusicFeaturePlayCacheProgress)(double progress);
typedef void (^MTMusicFeatureDownloadComplete)();
typedef void (^MTMusicFeaturePlayCacheComplete)();

@class DOUAudioStreamer;
@interface MTMusicFeature : NSObject

/**
 *  根据传入的audioFile初始化一个MTMusicFeature
 *
 *  @param audioFile 继承了DOUAudioFile协议的audiofile
 *
 *  @return MTMusicFeature
 */
- (instancetype)initMusicFeatureWithAudioFile:(id<DOUAudioFile>)audioFile;

/**
 *  开始某一个类型的MTMusicFeature
 *
 *  @param type MTMusicFeatureType
 */
- (void)startWithType:(MTMusicFeatureType)type;

/**
 *  暂停某一个类型的MTMusicFeature
 *
 *  @param type MTMusicFeatureType
 */
- (void)pauseWithType:(MTMusicFeatureType)type;

/**
 *  取消某一个类型的MTMusicFeature
 *
 *  @param type MTMusicFeatureType
 */
- (void)cancelWithType:(MTMusicFeatureType)type;

/**
 *  根据传入的指定model删除对应model下载完的文件
 *
 *  @param audioFile 继承了DOUAudioFile协议的audioFile
 */
- (void)clearFileWithAudioFile:(id<DOUAudioFile>)audioFile;

@property (nonatomic, copy) MTMusicFeatureDownloadProgress downloadProgress;    /** 下载进度的block回调 **/
@property (nonatomic, copy) MTMusicFeatureDownloadComplete downloadComplete;    /** 下载完成时候blocl回调 **/
@property (nonatomic, copy) MTMusicFeaturePlayCacheProgress playCacheProgress;
@property (nonatomic, copy) MTMusicFeaturePlayCacheComplete playCacheComplete;

@property (nonatomic, strong) DOUAudioStreamer *streamer;   /** 播放器 **/

@property (nonatomic, assign, readonly) BOOL localFileExist;    /**< 本地是否已经存在文件 **/
@end
