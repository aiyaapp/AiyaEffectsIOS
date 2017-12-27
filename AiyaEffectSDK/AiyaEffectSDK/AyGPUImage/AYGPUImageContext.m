//
//  AYGPUImageContext.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageContext.h"

#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"

#define MAXSHADERPROGRAMSALLOWEDINCACHE 40

dispatch_queue_attr_t AYGPUImageDefaultQueueAttribute(void)
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
    return nil;
}

void runAYSynchronouslyOnContextQueue(AYGPUImageContext *context, void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [context contextQueue];
    if (videoProcessingQueue) {
        if (dispatch_get_specific([context contextKey]))
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
    }else {
        block();
    }
}

@interface AYGPUImageContext()
{
    NSMutableDictionary *shaderProgramCache;
    EAGLSharegroup *_sharegroup;
    
    BOOL _newGLContext;
}

@end

@implementation AYGPUImageContext

@synthesize context = _context;
@synthesize contextQueue = _contextQueue;
@synthesize contextKey = _contextKey;
@synthesize coreVideoTextureCache = _coreVideoTextureCache;
@synthesize framebufferCache = _framebufferCache;

- (id)init{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    if ([EAGLContext currentContext]) {
        [self initWithCurrentGLContext];
    }else {
        [self initWithNewGLContext];
    }
    
    [self context];
    
    return self;
}

static int specificKey;

- (void)initWithNewGLContext;
{
    _contextQueue = dispatch_queue_create("com.aiyaapp.AYGPUImage", AYGPUImageDefaultQueueAttribute());
    
    CFStringRef specificValue = CFSTR("AYGPUImageQueue");
    dispatch_queue_set_specific(_contextQueue,
                                &specificKey,
                                (void*)specificValue,
                                (dispatch_function_t)CFRelease);
    
    shaderProgramCache = [[NSMutableDictionary alloc] init];
    
    _newGLContext = YES;
    
}

- (void)initWithCurrentGLContext;
{
    
    shaderProgramCache = [[NSMutableDictionary alloc] init];
    
    _newGLContext = NO;
}

- (void *)contextKey {
    return &specificKey;
}

- (void)useAsCurrentContext;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (GLint)maximumTextureSizeForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxTextureSize = 0;
    
    dispatch_once(&pred, ^{
        [self useAsCurrentContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });
    
    return maxTextureSize;
}

- (GLint)maximumTextureUnitsForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxTextureUnits = 0;
    
    dispatch_once(&pred, ^{
        [self useAsCurrentContext];
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
    });
    
    return maxTextureUnits;
}

- (GLint)maximumVaryingVectorsForThisDevice;
{
    static dispatch_once_t pred;
    static GLint maxVaryingVectors = 0;
    
    dispatch_once(&pred, ^{
        [self useAsCurrentContext];
        glGetIntegerv(GL_MAX_VARYING_VECTORS, &maxVaryingVectors);
    });
    
    return maxVaryingVectors;
}

- (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
{
    static dispatch_once_t pred;
    static NSArray *extensionNames = nil;
    
    // Cache extensions for later quick reference, since this won't change for a given device
    dispatch_once(&pred, ^{
        [self useAsCurrentContext];
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extensionsString componentsSeparatedByString:@" "];
    });
    
    return [extensionNames containsObject:extension];
}


// http://www.khronos.org/registry/gles/extensions/EXT/EXT_texture_rg.txt

- (BOOL)deviceSupportsRedTextures;
{
    static dispatch_once_t pred;
    static BOOL supportsRedTextures = NO;
    
    dispatch_once(&pred, ^{
        supportsRedTextures = [self deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    
    return supportsRedTextures;
}

- (BOOL)deviceSupportsFramebufferReads;
{
    static dispatch_once_t pred;
    static BOOL supportsFramebufferReads = NO;
    
    dispatch_once(&pred, ^{
        supportsFramebufferReads = [self deviceSupportsOpenGLESExtension:@"GL_EXT_shader_framebuffer_fetch"];
    });
    
    return supportsFramebufferReads;
}

- (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;
{
    GLint maxTextureSize = [self maximumTextureSizeForThisDevice];
    if ( (inputSize.width < maxTextureSize) && (inputSize.height < maxTextureSize) )
    {
        return inputSize;
    }
    
    CGSize adjustedSize;
    if (inputSize.width > inputSize.height)
    {
        adjustedSize.width = (CGFloat)maxTextureSize;
        adjustedSize.height = ((CGFloat)maxTextureSize / inputSize.width) * inputSize.height;
    }
    else
    {
        adjustedSize.height = (CGFloat)maxTextureSize;
        adjustedSize.width = ((CGFloat)maxTextureSize / inputSize.height) * inputSize.width;
    }
    
    return adjustedSize;
}

- (void)presentBufferForDisplay;
{
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (AYGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
{
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    AYGLProgram *programFromCache = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];
    
    if (programFromCache == nil)
    {
        programFromCache = [[AYGLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;
{
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    
    _sharegroup = sharegroup;
}

- (EAGLContext *)createContext;
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
    NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The AYGPUImage framework requires OpenGL ES 2.0 support to work.");
    return context;
}

#pragma mark -
#pragma mark Manage fast texture upload

+ (BOOL)supportsFastTextureUpload;
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
#endif
}

#pragma mark -
#pragma mark Accessors

- (EAGLContext *)context;
{
    if (_newGLContext) {
        if (_context == nil)
        {
            _context = [self createContext];
            [EAGLContext setCurrentContext:_context];
            
            // Set up a few global settings for the image processing pipeline
            glDisable(GL_DEPTH_TEST);
        }
    }else {
        _context = [EAGLContext currentContext];
    }
    
    return _context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL)
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[self context], NULL, &_coreVideoTextureCache);
#endif
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
    }
    
    return _coreVideoTextureCache;
}

- (AYGPUImageFramebufferCache *)framebufferCache;
{
    if (_framebufferCache == nil)
    {
        _framebufferCache = [[AYGPUImageFramebufferCache alloc] initWithContext:self];
    }
    
    return _framebufferCache;
}
@end
