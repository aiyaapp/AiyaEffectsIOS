//
//  AYGPUImageOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@implementation AYGPUImageOutput

@synthesize outputTextureOptions = _outputTextureOptions;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    targets = [[NSMutableArray alloc] init];
    
    // set default texture options
    _outputTextureOptions.minFilter = GL_LINEAR;
    _outputTextureOptions.magFilter = GL_LINEAR;
    _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.internalFormat = GL_RGBA;
    _outputTextureOptions.format = GL_BGRA;
    _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    
    self.context = context;
    
    return self;
}

- (void)dealloc
{
    [self removeAllTargets];
}

#pragma mark -
#pragma mark Managing targets

- (AYGPUImageFramebuffer *)framebufferForOutput;
{
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer;
{
    outputFramebuffer = nil;
}

- (NSArray*)targets;
{
    return [NSArray arrayWithArray:targets];
}

- (void)addTarget:(id<AYGPUImageInput>)newTarget;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [targets addObject:newTarget];
    });
}

- (void)removeTarget:(id<AYGPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [targets removeObject:targetToRemove];
    });
}

- (void)removeAllTargets;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [targets removeAllObjects];
    });
}

@end
