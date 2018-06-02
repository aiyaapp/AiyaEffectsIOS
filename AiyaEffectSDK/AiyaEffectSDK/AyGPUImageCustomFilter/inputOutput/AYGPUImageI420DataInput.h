//
//  AYGPUImageI420DataInput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/27.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@interface AYGPUImageI420DataInput : AYGPUImageOutput

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

/**
 处理YUV数据
 */
- (void)processWithYData:(void *)yData uData:(void *)uData vData:(void *)vData width:(int)width height:(int)height;

@end
