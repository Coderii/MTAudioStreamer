//
//  MTOperationFileProtocol.h
//  MTDemo0729
//
//  Created by Cheng on 16/8/2.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DOUAudioFile.h"

@class MTMusicOperation;
@protocol MTOperationFileProtocol <NSObject, DOUAudioFile>

@required
@property (nonatomic, strong) MTMusicOperation *operation;  /** 继承了DOUAudioFile协议的MTOperationFileProtocol的model中的operation **/

@end
