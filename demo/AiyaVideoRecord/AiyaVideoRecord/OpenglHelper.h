//
//  OpenglHelper.h
//  MicoBeautyDemo
//
//  Created by 汪洋 on 2017/8/10.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>

void runSynchronouslyOnOpenglHelperContextQueue(void (^block)(void));

@interface OpenglHelper : NSObject

+ (OpenglHelper *)share;

@property(readonly, nonatomic) dispatch_queue_t contextQueue;

@property(readonly, nonatomic) void *contextKey;

- (void)useShareGroup:(EAGLSharegroup *)shareGroup;

- (void)useAsCurrentContext;

- (EAGLContext *)context;

- (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;

- (BOOL)deviceSupportsRedTextures;

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache ;

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const NSString *)shaderString;

- (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString;

@end
