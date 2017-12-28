#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

@class AYYEGLProgram;
@class AYYEGPUImageFramebuffer;

#import "AYYEGPUImageFramebufferCache.h"
#import "AYYEGPUImageConstants.h"

void runAYYESynchronouslyOnContextQueue(AYYEGPUImageContext *context, void (^block)(void));

#define AYYEGPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kAYYEGPUImageRotateLeft || (rotation) == kAYYEGPUImageRotateRight || (rotation) == kAYYEGPUImageRotateRightFlipVertical || (rotation) == kAYYEGPUImageRotateRightFlipHorizontal)

@interface AYYEGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, nonatomic) void *contextKey;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly, retain, nonatomic) AYYEGPUImageFramebufferCache *framebufferCache;

- (void)useAsCurrentContext;

- (GLint)maximumTextureSizeForThisDevice;
- (GLint)maximumTextureUnitsForThisDevice;
- (GLint)maximumVaryingVectorsForThisDevice;
- (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
- (BOOL)deviceSupportsRedTextures;
- (BOOL)deviceSupportsFramebufferReads;
- (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (AYYEGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;

@end

@protocol AYYEGPUImageInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(AYYEGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(AYYEGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (void)endProcessing;
@end
