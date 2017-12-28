#import <UIKit/UIKit.h>

#import "AYYEGPUImageFramebuffer.h"
#import "AYYEGPUImageContext.h"

@interface AYYEGPUImageOutput : NSObject
{
    AYYEGPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
    
    CGSize inputTextureSize, cachedMaximumOutputSize;
}

@property (nonatomic, weak) AYYEGPUImageContext *context;
@property(nonatomic, copy) void(^frameProcessingCompletionBlock)(AYYEGPUImageOutput*, CMTime);
@property(readwrite, nonatomic) AYYEGPUTextureOptions outputTextureOptions;

- (id)initWithContext:(AYYEGPUImageContext *)context;

- (void)setInputFramebufferForTarget:(id<AYYEGPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;

- (AYYEGPUImageFramebuffer *)framebufferForOutput;

- (void)removeOutputFramebuffer;

- (NSArray*)targets;

- (void)addTarget:(id<AYYEGPUImageInput>)newTarget;

- (void)addTarget:(id<AYYEGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;

- (void)removeTarget:(id<AYYEGPUImageInput>)targetToRemove;

- (void)removeAllTargets;


@end
