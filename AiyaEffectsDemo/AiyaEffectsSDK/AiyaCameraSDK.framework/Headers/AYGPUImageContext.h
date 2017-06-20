#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"
#import "AYGPUImageFramebufferCache.h"

#define AYGPUImageRotationSwapsWidthAndHeight(rotation) ((rotation) == kAYGPUImageRotateLeft || (rotation) == kAYGPUImageRotateRight || (rotation) == kAYGPUImageRotateRightFlipVertical || (rotation) == kAYGPUImageRotateRightFlipHorizontal)

typedef NS_ENUM(NSUInteger, AYGPUImageRotationMode) {
	kAYGPUImageNoRotation,
	kAYGPUImageRotateLeft,
	kAYGPUImageRotateRight,
	kAYGPUImageFlipVertical,
	kAYGPUImageFlipHorizonal,
	kAYGPUImageRotateRightFlipVertical,
	kAYGPUImageRotateRightFlipHorizontal,
	kAYGPUImageRotate180
};

@interface AYGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) AYGLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly) AYGPUImageFramebufferCache *framebufferCache;

+ (void *)contextKey;
+ (AYGPUImageContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (AYGPUImageFramebufferCache *)sharedFramebufferCache;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;
+ (void)setActiveShaderProgram:(AYGLProgram *)shaderProgram;
- (void)setContextShaderProgram:(AYGLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (GLint)maximumVaryingVectorsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

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
- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end
