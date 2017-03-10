#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "AYGPUImageFramebuffer.h"

@interface AYGPUImageFramebufferCache : NSObject

// Framebuffer management
- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(AYGPUTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(AYGPUImageFramebuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(AYGPUImageFramebuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(AYGPUImageFramebuffer *)framebuffer;

@end
