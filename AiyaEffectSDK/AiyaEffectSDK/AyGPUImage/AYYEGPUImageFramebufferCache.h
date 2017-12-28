#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "AYYEGPUImageConstants.h"

@class AYYEGPUImageFramebuffer;
@class AYYEGPUImageContext;

@interface AYYEGPUImageFramebufferCache : NSObject

// Framebuffer management
- (id)initWithContext:(AYYEGPUImageContext *)context;

- (AYYEGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(AYYEGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
- (AYYEGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;

- (void)returnFramebufferToCache:(AYYEGPUImageFramebuffer *)framebuffer;

@end
