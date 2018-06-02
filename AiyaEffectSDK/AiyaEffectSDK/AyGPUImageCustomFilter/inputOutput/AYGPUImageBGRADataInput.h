//
//  AYGPUImageBGRADataInput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@interface AYGPUImageBGRADataInput : AYGPUImageOutput

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

/**
 处理BGRA数据
 
 @param pixelBuffer BGRA格式的pixelBuffer
 */
- (void)processWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;


/**
 处理BGRA数据

 @param bgraData 原始数据
 */
- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height;

@end
