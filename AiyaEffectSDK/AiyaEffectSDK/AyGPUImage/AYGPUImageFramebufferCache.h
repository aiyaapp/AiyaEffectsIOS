//
//  AYGPUImageFramebufferCache.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "AYGPUImageConstants.h"

@class AYGPUImageFramebuffer;
@class AYGPUImageContext;

@interface AYGPUImageFramebufferCache : NSObject

// Framebuffer management
- (id)initWithContext:(AYGPUImageContext *)context;

- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(AYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;

- (void)returnFramebufferToCache:(AYGPUImageFramebuffer *)framebuffer;

@end
