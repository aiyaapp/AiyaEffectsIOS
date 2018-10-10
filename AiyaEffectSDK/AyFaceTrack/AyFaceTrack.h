//
//  AyFaceTrack.h
//  AyFaceTrack
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AyFaceTrack : NSObject

/**
 人脸跟踪
 */
- (void)trackWithPixelBuffer:(unsigned char*)pixelBuffer bufferWidth:(int)width bufferHeight:(int)height trackData:(void **)trackData;

@end
