//
//  AYGPUImageFramebufferCache.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFramebufferCache.h"

#import "AYGPUImageOutput.h"
#import "AYGPUImageFramebuffer.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageFramebufferCache()
{
    NSMutableDictionary *framebufferCache;
}

@property (nonatomic, weak) AYGPUImageContext *context;

- (NSString *)hashForSize:(CGSize)size textureOptions:(AYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

@end


@implementation AYGPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.context = context;
    
    framebufferCache = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(AYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (missCVPixelBuffer)
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-CVBF", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
    else
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(AYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    __block AYGPUImageFramebuffer *framebufferFromCache = nil;
    runAYSynchronouslyOnContextQueue(self.context, ^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];
        
        if (frameBufferArr != nil && frameBufferArr.count > 0){
            framebufferFromCache = [frameBufferArr lastObject];
            [frameBufferArr removeLastObject];
            [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        }
        
        if (framebufferFromCache == nil)
        {
            framebufferFromCache = [[AYGPUImageFramebuffer alloc] initWithContext:self.context size:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        }
    });
    
    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (AYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    AYGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions missCVPixelBuffer:missCVPixelBuffer];
}

- (void)returnFramebufferToCache:(AYGPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        CGSize framebufferSize = framebuffer.size;
        AYGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions missCVPixelBuffer:framebuffer.missCVPixelBuffer];
        
        NSMutableArray *frameBufferArr = [framebufferCache objectForKey:lookupHash];
        if (!frameBufferArr) {
            frameBufferArr = [NSMutableArray array];
        }
        
        [frameBufferArr addObject:framebuffer];
        [framebufferCache setObject:frameBufferArr forKey:lookupHash];
        
    });
}

@end

