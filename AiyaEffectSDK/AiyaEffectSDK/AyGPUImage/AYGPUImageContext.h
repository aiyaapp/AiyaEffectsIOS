//
//  AYGPUImageContext.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

@class AYGLProgram;
@class AYGPUImageFramebuffer;

#import "AYGPUImageFramebufferCache.h"
#import "AYGPUImageConstants.h"

void runAYSynchronouslyOnContextQueue(AYGPUImageContext *context, void (^block)(void));

@interface AYGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, nonatomic) void *contextKey;

@property(readonly, retain, nonatomic) EAGLContext *context;

@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly, retain, nonatomic) AYGPUImageFramebufferCache *framebufferCache;

- (instancetype)initWithNewGLContext;

- (instancetype)initWithCurrentGLContext;

- (void)useAsCurrentContext;

- (void)presentBufferForDisplay;

- (AYGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

@end

@protocol AYGPUImageInput <NSObject>

- (void)setInputSize:(CGSize)newSize;
- (void)setInputFramebuffer:(AYGPUImageFramebuffer *)newInputFramebuffer;
- (void)newFrameReady;

@end
