//
//  AYGPUImageOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AYGPUImageFramebuffer.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageOutput : NSObject
{
    AYGPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets, *targetTextureIndices;
    
    CGSize inputTextureSize, cachedMaximumOutputSize;
}

@property (nonatomic, weak) AYGPUImageContext *context;
@property(nonatomic, copy) void(^frameProcessingCompletionBlock)(AYGPUImageOutput*, CMTime);
@property(readwrite, nonatomic) AYGPUTextureOptions outputTextureOptions;

- (id)initWithContext:(AYGPUImageContext *)context;

- (void)setInputFramebufferForTarget:(id<AYGPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;

- (AYGPUImageFramebuffer *)framebufferForOutput;

- (void)removeOutputFramebuffer;

- (NSArray*)targets;

- (void)addTarget:(id<AYGPUImageInput>)newTarget;

- (void)addTarget:(id<AYGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;

- (void)removeTarget:(id<AYGPUImageInput>)targetToRemove;

- (void)removeAllTargets;

@end
