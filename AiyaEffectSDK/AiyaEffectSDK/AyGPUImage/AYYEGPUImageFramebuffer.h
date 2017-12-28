#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#import "AYYEGPUImageContext.h"
#import "AYYEGPUImageConstants.h"

@interface AYYEGPUImageFramebuffer : NSObject

@property(readonly) CGSize size;
@property(readonly) AYYEGPUTextureOptions textureOptions;
@property(readonly) GLuint texture;
@property(readonly) BOOL missCVPixelBuffer;
@property(readonly) NSUInteger framebufferReferenceCount;
@property(nonatomic, weak) AYYEGPUImageContext *context;

// Initialization and teardown

- (id)initWithContext:(AYYEGPUImageContext *)context size:(CGSize)framebufferSize textureOptions:(AYYEGPUTextureOptions)fboTextureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

// Usage
- (void)activateFramebuffer;

// Reference counting
- (void)lock;
- (void)unlock;
- (void)clearAllLocks;

// Raw data bytes
- (void)lockForReading;
- (void)unlockAfterReading;
- (NSUInteger)bytesPerRow;
- (GLubyte *)byteBuffer;
- (CVPixelBufferRef)pixelBuffer;
- (UIImage *)image;

@end
