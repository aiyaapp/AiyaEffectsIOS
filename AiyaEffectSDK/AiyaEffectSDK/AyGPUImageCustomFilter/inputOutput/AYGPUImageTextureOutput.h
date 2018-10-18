//
//  AYGPUImageTextureOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageTextureOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

/**
 设置输出BGRA纹理

 @param texture BGRA纹理
 */
- (void)setOutputWithBGRATexture:(GLint)texture width:(int)width height:(int)height;

@end
