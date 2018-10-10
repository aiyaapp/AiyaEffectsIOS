//
//  AYGPUImageI420DataOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/27.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageI420DataOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

/**
 设置输出YUV数据
 */
- (void)setOutputWithYData:(void *)YData uData:(void *)uData vData:(void *)vData width:(int)width height:(int)height;

@end
