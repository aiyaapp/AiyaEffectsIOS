//
//  OpenglHelper.m
//  MicoBeautyDemo
//
//  Created by 汪洋 on 2017/8/10.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "OpenglHelper.h"

@interface OpenglHelper (){
    EAGLContext *_context;
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
}

@end

@implementation OpenglHelper

- (void)useAsCurrentContext {
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
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

- (void)dealloc{
    if (coreVideoTextureCache) {
        CFRelease(coreVideoTextureCache);
        coreVideoTextureCache = nil;
    }
}

@end
