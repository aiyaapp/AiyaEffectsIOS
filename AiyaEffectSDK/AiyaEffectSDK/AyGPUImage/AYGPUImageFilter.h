//
//  AYGPUImageFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "AYGPUImageOutput.h"
#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"
#import "AYGPUImageConstants.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define AYGPUImageHashIdentifier #
#define AYGPUImageWrappedLabel(x) x
#define AYGPUImageEscapedHashIdentifier(a) AYGPUImageWrappedLabel(AYGPUImageHashIdentifier)a

extern NSString *const kAYGPUImageVertexShaderString;
extern NSString *const kAYGPUImagePassthroughFragmentShaderString;

@interface AYGPUImageFilter : AYGPUImageOutput <AYGPUImageInput>
{
    
    AYGPUImageFramebuffer *firstInputFramebuffer;
    
    AYGLProgram *filterProgram;
    
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
}

@property(readonly) CVPixelBufferRef renderTarget;

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYGPUImageContext *)context;

- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(AYGPUImageRotationMode)rotationMode;
+ (BOOL)needExchangeWidthAndHeightWithRotation:(AYGPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;

- (void)informTargetsAboutNewFrame;

@end
