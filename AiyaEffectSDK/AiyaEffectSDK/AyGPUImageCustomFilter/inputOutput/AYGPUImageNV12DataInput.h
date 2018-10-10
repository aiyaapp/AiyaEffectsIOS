//
//  AYGPUImageNV12DataInput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/26.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

extern GLfloat kAYColorConversion601FullRangeDefault[];

@interface AYGPUImageNV12DataInput : AYGPUImageOutput

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

/**
 处理YUV数据
 */
- (void)processWithYData:(void *)yData uvData:(void *)uvData width:(int)width height:(int)height;

/**
 处理YUV数据, 格式为:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 */
- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
