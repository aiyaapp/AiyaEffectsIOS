//
//  AYGPUImageBGRADataOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageBGRADataOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

/**
 设置输出BGRA数据

 @param pixelBuffer 用于存储输出数据的CVPixelBuffer
 */
- (void)setOutputWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 设置输出BGRA数据

 @param bgraData 原始BGRA数据
 @param width 宽
 @param height 高
 */
- (void)setOutputWithBGRAData:(void *)bgraData width:(int)width height:(int)height;

@end
