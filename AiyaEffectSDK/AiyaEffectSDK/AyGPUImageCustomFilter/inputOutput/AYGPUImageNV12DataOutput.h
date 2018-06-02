//
//  AYGPUImageNV12DataOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/26.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

extern GLfloat kAYColorConversionRGBDefault[];

@interface AYGPUImageNV12DataOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

/**
 设置输出YUV数据
 */
- (void)setOutputWithYData:(void *)YData uvData:(void *)uvData width:(int)width height:(int)height;


/**
 设置输出YUV数据, 格式:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
 */
- (void)setOutputWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
