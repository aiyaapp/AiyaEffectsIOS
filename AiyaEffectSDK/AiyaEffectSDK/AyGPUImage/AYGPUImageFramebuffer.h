//
//  AYGPUImageFramebuffer.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#import "AYGPUImageContext.h"
#import "AYGPUImageConstants.h"

@interface AYGPUImageFramebuffer : NSObject

@property(readonly) CGSize size;
@property(readonly) AYGPUTextureOptions textureOptions;
@property(readonly) GLuint texture;
@property(readonly) BOOL missCVPixelBuffer;
@property(readonly) NSUInteger framebufferReferenceCount;
@property(nonatomic, weak) AYGPUImageContext *context;

// Initialization and teardown

- (id)initWithContext:(AYGPUImageContext *)context size:(CGSize)framebufferSize textureOptions:(AYGPUTextureOptions)fboTextureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

// Usage
- (void)activateFramebuffer;

// Reference counting
- (void)lock;
- (void)unlock;
- (void)clearAllLocks;

//// Raw data bytes
- (void)lockForReading;
- (void)unlockAfterReading;
- (NSUInteger)bytesPerRow;
- (GLubyte *)byteBuffer;
- (CVPixelBufferRef)pixelBuffer;
- (UIImage *)image;

@end
