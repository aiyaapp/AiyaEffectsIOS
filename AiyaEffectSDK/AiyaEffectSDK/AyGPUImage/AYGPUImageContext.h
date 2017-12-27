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

#define AYGPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kAYGPUImageRotateLeft || (rotation) == kAYGPUImageRotateRight || (rotation) == kAYGPUImageRotateRightFlipVertical || (rotation) == kAYGPUImageRotateRightFlipHorizontal)

@interface AYGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, nonatomic) void *contextKey;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly, retain, nonatomic) AYGPUImageFramebufferCache *framebufferCache;

- (void)useAsCurrentContext;

- (GLint)maximumTextureSizeForThisDevice;
- (GLint)maximumTextureUnitsForThisDevice;
- (GLint)maximumVaryingVectorsForThisDevice;
- (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
- (BOOL)deviceSupportsRedTextures;
- (BOOL)deviceSupportsFramebufferReads;
- (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (AYGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

@protocol AYGPUImageInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(AYGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(AYGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (void)endProcessing;
@end
