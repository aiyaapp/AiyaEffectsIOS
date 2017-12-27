#import <AVFoundation/AVFoundation.h>

#import "AYYEGPUImageOutput.h"
#import "AYYEGLProgram.h"
#import "AYYEGPUImageFramebuffer.h"
#import "AYYEGPUImageConstants.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define AYYEGPUImageHashIdentifier #
#define AYYEGPUImageWrappedLabel(x) x
#define AYYEGPUImageEscapedHashIdentifier(a) AYYEGPUImageWrappedLabel(AYYEGPUImageHashIdentifier)a

extern NSString *const kAYYEGPUImageVertexShaderString;
extern NSString *const kAYYEGPUImagePassthroughFragmentShaderString;

@interface AYYEGPUImageFilter : AYYEGPUImageOutput <AYYEGPUImageInput>
{
    
    AYYEGPUImageFramebuffer *firstInputFramebuffer;
    
    AYYEGLProgram *filterProgram;
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
    GLfloat backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;
    
    BOOL isEndProcessing;

    CGSize currentFilterSize;
    AYYEGPUImageRotationMode inputRotation;
        
    NSMutableDictionary *uniformStateRestorationBlocks;
}

@property(readonly) CVPixelBufferRef renderTarget;


- (id)initWithContext:(AYYEGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYYEGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(AYYEGPUImageContext *)context;

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;

- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(AYYEGPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;

/// @name Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
- (void)setFloatVec3:(AYYEGPUVector3)newVec3 forUniformName:(NSString *)uniformName;
- (void)setFloatVec4:(AYYEGPUVector4)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

- (void)setMatrix3f:(AYYEGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setMatrix4f:(AYYEGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setVec3:(AYYEGPUVector3)vectorValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setVec4:(AYYEGPUVector4)vectorValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;
- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(AYYEGLProgram *)shaderProgram;

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(AYYEGLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;

@end
