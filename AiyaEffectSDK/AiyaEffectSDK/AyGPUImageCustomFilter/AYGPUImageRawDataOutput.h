//
//  AYGPUImageRawDataOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageRawDataOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) BOOL verticalFlip;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

/**
 输出BGRA数据

 @param pixelBuffer 用于存储输出数据的CVPixelBuffer
 */
- (void)setOutputCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
