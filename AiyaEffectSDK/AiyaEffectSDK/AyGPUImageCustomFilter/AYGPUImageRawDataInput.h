//
//  AYGPUImageRawDataInput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@interface AYGPUImageRawDataInput : AYGPUImageOutput

@property (nonatomic, assign) BOOL verticalFlip;

/**
 输入BGRA数据
 
 @param pixelBuffer BGRA格式的pixelBuffer
 */
- (void)processBGRADataWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
