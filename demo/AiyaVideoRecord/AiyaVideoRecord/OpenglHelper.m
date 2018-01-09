//
//  OpenglHelper.m
//  MicoBeautyDemo
//
//  Created by 汪洋 on 2017/8/10.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "OpenglHelper.h"
#import <UIKit/UIKit.h>

static dispatch_queue_attr_t GPUImageDefaultQueueAttribute(void) {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending){
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
    return nil;
}

void runSynchronouslyOnOpenglHelperContextQueue(void (^block)(void)) {
    dispatch_queue_t videoProcessingQueue = [[OpenglHelper share] contextQueue];
    if (videoProcessingQueue) {
        if (dispatch_get_specific([[OpenglHelper share] contextKey])) {
            block();
        }else {
            dispatch_sync(videoProcessingQueue, block);
        }
    }else {
        block();
    }
}

@interface OpenglHelper (){
    EAGLContext *_context;
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
}

@end

@implementation OpenglHelper

@synthesize contextQueue = _contextQueue;

+ (OpenglHelper *)share{
    static dispatch_once_t onceToken;
    static OpenglHelper *helper;
    dispatch_once(&onceToken, ^{
        helper = [[OpenglHelper alloc] privateInit];
    });
    
    return helper;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        @throw [NSException exceptionWithName:@"Wrong usage" reason:@"This is a single case." userInfo:nil];
    }
    return self;
}

static int specificKey;

- (instancetype)privateInit{
    id class = [super init];
    if (class) {
        _contextQueue = dispatch_queue_create("com.aiyaapp.OpenglHelper", GPUImageDefaultQueueAttribute());
        
        CFStringRef specificValue = CFSTR("AYGPUImageQueue");
        dispatch_queue_set_specific(_contextQueue,
                                    &specificKey,
                                    (void*)specificValue,
                                    (dispatch_function_t)CFRelease);
    }
    return class;
}

- (void *)contextKey {
    return &specificKey;
}

- (void)useAsCurrentContext {
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (void)useShareGroup:(EAGLSharegroup *)shareGroup{
    if (_context == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:shareGroup];
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }

}

- (EAGLContext *)context {
    if (_context == nil)
    {
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:_context];
        
        // Set up a few global settings for the image processing pipeline
        glDisable(GL_DEPTH_TEST);
    }
    
    return _context;
}

- (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension {
    static dispatch_once_t pred;
    static NSArray *extensionNames = nil;
    
    dispatch_once(&pred, ^{
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extensionsString componentsSeparatedByString:@" "];
    });
    
    return [extensionNames containsObject:extension];
}

- (BOOL)deviceSupportsRedTextures {
    static dispatch_once_t pred;
    static BOOL supportsRedTextures = NO;
    
    dispatch_once(&pred, ^{
        supportsRedTextures = [self deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    
    return supportsRedTextures;
}



- (CVOpenGLESTextureCacheRef)coreVideoTextureCache {
    if (coreVideoTextureCache == NULL){
        EAGLContext* context = [self context];
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &coreVideoTextureCache);
        
        if (err){
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    
    return coreVideoTextureCache;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const NSString *)shaderString{
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source){
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0){
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Failed to compile shader %s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

- (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString{
    
    GLuint program = glCreateProgram();
    GLuint vertShader = 0, fragShader = 0;
    if (![self compileShader:&vertShader
                        type:GL_VERTEX_SHADER
                      string:vShaderString]){
        NSLog(@"Failed to compile vertex shader");
    }
    
    if (![self compileShader:&fragShader
                        type:GL_FRAGMENT_SHADER
                      string:fShaderString]){
        NSLog(@"Failed to compile fragment shader");
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        NSLog(@"Failed to link shader");
    
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    return program;
}

@end
