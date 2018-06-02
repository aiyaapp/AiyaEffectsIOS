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
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
    
    BOOL isEndProcessing;
    
    CGSize currentFilterSize;
    AYGPUImageRotationMode inputRotation;
    
    NSMutableDictionary *uniformStateRestorationBlocks;
}

@property(readonly) CVPixelBufferRef renderTarget;

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYGPUImageContext *)context;

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;

- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(AYGPUImageRotationMode)rotationMode;
+ (BOOL)needExchangeWidthAndHeightWithRotation:(AYGPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;

/// @name Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
- (void)setFloatVec3:(AYGPUVector3)newVec3 forUniformName:(NSString *)uniformName;
- (void)setFloatVec4:(AYGPUVector4)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

- (void)setMatrix3f:(AYGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setMatrix4f:(AYGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setVec3:(AYGPUVector3)vectorValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setVec4:(AYGPUVector4)vectorValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(AYGLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;

@end
