//
//  AiyaYFBeautifyProcess.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/23.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AiyaCameraSDK/AiyaGPUImageYFBeautifyFilter.h>

@interface AiyaYFBeautifyProcess : NSObject

/** 美颜等级 */
@property (nonatomic, assign) AIYA_YF_BEAUTY_LEVEL beautyLevel;

/** 处理数据 */
- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
