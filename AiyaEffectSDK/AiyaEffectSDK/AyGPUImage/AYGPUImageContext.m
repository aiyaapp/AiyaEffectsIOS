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

static int specificKey;

- (instancetype)init {
    @throw [NSException exceptionWithName:@"init Exception" reason:@"use initWithNewGLContext or initWithCurrentGLContext" userInfo:nil];
}

- (instancetype)initWithNewGLContext;
{
    self = [super init];
    if (self) {
        _contextQueue = dispatch_queue_create("com.aiyaapp.AYGPUImage", AYGPUImageDefaultQueueAttribute());
        
        CFStringRef specificValue = CFSTR("AYGPUImageQueue");
        dispatch_queue_set_specific(_contextQueue,
                                    &specificKey,
                                    (void*)specificValue,
                                    (dispatch_function_t)CFRelease);
        
        shaderProgramCache = [[NSMutableDictionary alloc] init];
        
        dispatch_sync(_contextQueue, ^{
            _context = [self createContext];
        });
    }
    return self;
}

- (instancetype)initWithCurrentGLContext
{
    self = [super init];
    if (self) {
        shaderProgramCache = [[NSMutableDictionary alloc] init];
        
        _context = [EAGLContext currentContext];
    }
    return self;
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
#pragma mark Accessors

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
        
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
