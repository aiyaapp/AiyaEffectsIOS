//
//  AYGPUImageOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@implementation AYGPUImageOutput

@synthesize frameProcessingCompletionBlock = _frameProcessingCompletionBlock;
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
    targetTextureIndices = [[NSMutableArray alloc] init];
    
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

- (void)setInputFramebufferForTarget:(id<AYGPUImageInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

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
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
}

- (void)addTarget:(id<AYGPUImageInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    runAYSynchronouslyOnContextQueue(self.context, ^{
//        [self setInputFramebufferForTarget:newTarget atIndex:textureLocation];
        [targets addObject:newTarget];
        [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
    });
}

- (void)removeTarget:(id<AYGPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
        [targetToRemove setInputRotation:kAYGPUImageNoRotation atIndex:textureIndexOfTarget];
        
        [targetTextureIndices removeObjectAtIndex:indexOfObject];
        [targets removeObject:targetToRemove];
        [targetToRemove endProcessing];
    });
}

- (void)removeAllTargets;
{
    cachedMaximumOutputSize = CGSizeZero;
    runAYSynchronouslyOnContextQueue(self.context, ^{
        for (id<AYGPUImageInput> targetToRemove in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
            [targetToRemove setInputRotation:kAYGPUImageNoRotation atIndex:textureIndexOfTarget];
        }
        [targets removeAllObjects];
        [targetTextureIndices removeAllObjects];
    });
}

#pragma mark -
#pragma mark Accessors

-(void)setOutputTextureOptions:(AYGPUTextureOptions)outputTextureOptions
{
    _outputTextureOptions = outputTextureOptions;
    
    if( outputFramebuffer.texture )
    {
        glBindTexture(GL_TEXTURE_2D,  outputFramebuffer.texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _outputTextureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

@end
