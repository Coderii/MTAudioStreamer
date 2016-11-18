//
//  NSString+MTSH256Path.m
//  Pods
//
//  Created by Cheng on 16/7/29.
//
//

#import "NSString+MTSH256Path.h"
#include <CommonCrypto/CommonDigest.h>

@implementation NSString (MTSH256Path)

+ (instancetype)mt_getFileDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return docDir;
}

+ (instancetype)mt_getRequestCachePathWithUrl:(NSURL *)url {
    NSString *pathName = [NSString stringWithFormat:@"%@.tmp", [NSString mt_sha256ForAudioFileURL:url]];
    NSString *fullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:pathName];
    return fullPath;
}

+ (instancetype)mt_sha256ForAudioFileURL:(NSURL *)audioFileURL {
    NSString *string = [audioFileURL absoluteString];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([string UTF8String], (CC_LONG)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding], hash);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (size_t i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
        [result appendFormat:@"%02x", hash[i]];
    }
    
    return result;
}

// get path
+ (instancetype)mt_getPathExtensionWithURL:(NSURL *)audioFileURL {
    return [audioFileURL.absoluteString pathExtension];
}

+ (instancetype)mt_getDisguiseFileWithUrl:(NSURL *)url {
    NSString *pathName = [NSString stringWithFormat:@"%@.tmp.tmp", [NSString mt_sha256ForAudioFileURL:url]];
    NSString *fullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:pathName];
    return fullPath;
}

@end
