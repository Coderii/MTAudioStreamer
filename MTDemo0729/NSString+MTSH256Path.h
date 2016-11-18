//
//  NSString+MTSH256Path.h
//  Pods
//
//  Created by Cheng on 16/7/29.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MTSH256Path)

/**
 *  获取沙盒目录下的Document文件
 *
 *  @return 路径名
 */
+ (instancetype)mt_getFileDocumentPath;

/**
 *  根据url获取请求得到的临时缓存路径
 *
 *  @param url 对应的请求的url
 *
 *  @return 临时缓存路径
 */
+ (instancetype)mt_getRequestCachePathWithUrl:(NSURL *)url;

/**
 *  根据audioFileURL得到sha256之后的文件名
 *
 *  @param audioFileURL url
 *
 *  @return 经过sha256处理后的文件名
 */
+ (instancetype)mt_sha256ForAudioFileURL:(NSURL *)audioFileURL;

/**
 *  根据url获取当前url请求的文件名后缀
 *
 *  @param audioFileURL 请求的url
 *
 *  @return 返回文件名后缀
 */
+ (instancetype)mt_getPathExtensionWithURL:(NSURL *)audioFileURL;

+ (instancetype)mt_getDisguiseFileWithUrl:(NSURL *)url;
@end
