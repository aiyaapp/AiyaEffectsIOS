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
    
    NSMutableArray *targets;
    
    CGSize inputTextureSize;
}

@property (nonatomic, weak) AYGPUImageContext *context;
@property(readwrite, nonatomic) AYGPUTextureOptions outputTextureOptions;

- (id)initWithContext:(AYGPUImageContext *)context;

- (AYGPUImageFramebuffer *)framebufferForOutput;

- (void)removeOutputFramebuffer;

- (NSArray*)targets;

- (void)addTarget:(id<AYGPUImageInput>)newTarget;

- (void)removeTarget:(id<AYGPUImageInput>)targetToRemove;

- (void)removeAllTargets;

@end
