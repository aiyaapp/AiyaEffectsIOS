//
//  AYGPUImageI420DataOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/27.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageI420DataOutput.h"
#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"
#import "AYGPUImageNV12DataOutput.h"

NSString *const kAY_Y_ConversionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 rgb;
     lowp vec3 yuv;
     rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     yuv = colorConversionMatrix * rgb;
     gl_FragColor = vec4(yuv.x, 0, 0, 0);
 }
 );

NSString *const kAY_U_ConversionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 rgb;
     lowp vec3 yuv;
     rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     yuv = colorConversionMatrix * rgb;
     gl_FragColor = vec4(yuv.y+0.5, 0, 0, 0);
 }
 );


NSString *const kAY_V_ConversionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 rgb;
     lowp vec3 yuv;
     rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     yuv = colorConversionMatrix * rgb;
     gl_FragColor = vec4(yuv.z+0.5, 0, 0, 0);
 }
 );

@interface AYGPUImageI420DataOutput (){
    AYGPUImageFramebuffer *firstInputFramebuffer;
    
    AYGLProgram *yProgram;
    GLint yPositionAttribute, yTextureCoordinateAttribute;
    GLint yInputTextureUniform;
    GLint yColorConversionUniform;
    
    AYGLProgram *uProgram;
    GLint uPositionAttribute, uTextureCoordinateAttribute;
    GLint uInputTextureUniform;
    GLint uColorConversionUniform;
    
    AYGLProgram *vProgram;
    GLint vPositionAttribute, vTextureCoordinateAttribute;
    GLint vInputTextureUniform;
    GLint vColorConversionUniform;
    
    GLuint yFrameBuffer;
    GLuint uFrameBuffer;
    GLuint vFrameBuffer;

    CVOpenGLESTextureRef yTextureRef;
    CVOpenGLESTextureRef uTextureRef;
    CVOpenGLESTextureRef vTextureRef;

    CVPixelBufferRef outputYPixelBuffer;
    CVPixelBufferRef outputUPixelBuffer;
    CVPixelBufferRef outputVPixelBuffer;

}

@property (nonatomic, weak) AYGPUImageContext *context;
@property (nonatomic, assign) CGSize inputSize;

@property (nonatomic, assign) void* outputYData;
@property (nonatomic, assign) void* outputUData;
@property (nonatomic, assign) void* outputVData;
@property (nonatomic, assign) int outputWidth;
@property (nonatomic, assign) int outputHeight;

@end

@implementation AYGPUImageI420DataOutput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _context = context;
    
    runAYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        
        yProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAY_Y_ConversionFragmentShaderString];
        
        if (!yProgram.initialized)
        {
            if (![yProgram link])
            {
                NSString *progLog = [yProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [yProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [yProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                yProgram = nil;
            }
        }
        
        yPositionAttribute = [yProgram attributeIndex:@"position"];
        yTextureCoordinateAttribute = [yProgram attributeIndex:@"inputTextureCoordinate"];
        yInputTextureUniform = [yProgram uniformIndex:@"inputImageTexture"];
        yColorConversionUniform = [yProgram uniformIndex:@"colorConversionMatrix"];
        
        uProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAY_U_ConversionFragmentShaderString];
        
        if (!uProgram.initialized)
        {
            if (![uProgram link])
            {
                NSString *progLog = [uProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [uProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [uProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                uProgram = nil;
            }
        }
        
        uPositionAttribute = [uProgram attributeIndex:@"position"];
        uTextureCoordinateAttribute = [uProgram attributeIndex:@"inputTextureCoordinate"];
        uInputTextureUniform = [uProgram uniformIndex:@"inputImageTexture"];
        uColorConversionUniform = [uProgram uniformIndex:@"colorConversionMatrix"];
        
        vProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAY_V_ConversionFragmentShaderString];
        
        if (!vProgram.initialized)
        {
            if (![vProgram link])
            {
                NSString *progLog = [vProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [vProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [vProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                vProgram = nil;
            }
        }
        
        vPositionAttribute = [vProgram attributeIndex:@"position"];
        vTextureCoordinateAttribute = [vProgram attributeIndex:@"inputTextureCoordinate"];
        vInputTextureUniform = [vProgram uniformIndex:@"inputImageTexture"];
        vColorConversionUniform = [vProgram uniformIndex:@"colorConversionMatrix"];
    });
        
    return self;
}

- (void)createoutputYPixelBufferWithWidth:(GLsizei)width height:(GLsizei)height{
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &outputYPixelBuffer);
    
    CFRelease(attrs);
    CFRelease(empty);
}

- (void)createoutputUPixelBufferWithWidth:(GLsizei)width height:(GLsizei)height{
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &outputUPixelBuffer);
    
    CFRelease(attrs);
    CFRelease(empty);
}

- (void)createoutputVPixelBufferWithWidth:(GLsizei)width height:(GLsizei)height{
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &outputVPixelBuffer);
    
    CFRelease(attrs);
    CFRelease(empty);
}

- (void)createyFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    glGenFramebuffers(1, &yFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, yFrameBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self.context coreVideoTextureCache], outputYPixelBuffer, NULL, GL_TEXTURE_2D, GL_RED_EXT, width, height, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &yTextureRef);
    
    glBindTexture(CVOpenGLESTextureGetTarget(yTextureRef), CVOpenGLESTextureGetName(yTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(yTextureRef), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)createuFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    glGenFramebuffers(1, &uFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, uFrameBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self.context coreVideoTextureCache], outputUPixelBuffer, NULL, GL_TEXTURE_2D, GL_RED_EXT, width, height, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &uTextureRef);
    
    glBindTexture(CVOpenGLESTextureGetTarget(uTextureRef), CVOpenGLESTextureGetName(uTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(uTextureRef), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)createvFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    glGenFramebuffers(1, &vFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, vFrameBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self.context coreVideoTextureCache], outputVPixelBuffer, NULL, GL_TEXTURE_2D, GL_RED_EXT, width, height, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &vTextureRef);
    
    glBindTexture(CVOpenGLESTextureGetTarget(vTextureRef), CVOpenGLESTextureGetName(vTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(vTextureRef), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    
    //==========> 绘制y数据
    [yProgram use];
    
    if (!yFrameBuffer) {
        [self createoutputYPixelBufferWithWidth:self.outputWidth height:self.outputHeight];
        [self createyFramebufferWithWidth:self.outputWidth height:self.outputHeight];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, yFrameBuffer);
    glViewport(0, 0, self.outputWidth, self.outputHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(yInputTextureUniform, 4);
    
    glUniformMatrix3fv(yColorConversionUniform, 1, GL_FALSE, kAYColorConversionRGBDefault);
    
    glVertexAttribPointer(yPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(yTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,[AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //==========> 绘制u数据
    
    [uProgram use];
    
    if (!uFrameBuffer) {
        [self createoutputUPixelBufferWithWidth:self.outputWidth/2 height:self.outputHeight/2];
        [self createuFramebufferWithWidth:self.outputWidth/2 height:self.outputHeight/2];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, uFrameBuffer);
    glViewport(0, 0, self.outputWidth/2, self.outputHeight/2);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(uInputTextureUniform, 4);
    
    glUniformMatrix3fv(yColorConversionUniform, 1, GL_FALSE, kAYColorConversionRGBDefault);
    
    glVertexAttribPointer(uPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(uTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //==========> 绘制v数据
    
    [vProgram use];
    
    if (!vFrameBuffer) {
        [self createoutputVPixelBufferWithWidth:self.outputWidth/2 height:self.outputHeight/2];
        [self createvFramebufferWithWidth:self.outputWidth/2 height:self.outputHeight/2];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, vFrameBuffer);
    glViewport(0, 0, self.outputWidth/2, self.outputHeight/2);

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(vInputTextureUniform, 4);
    
    glUniformMatrix3fv(yColorConversionUniform, 1, GL_FALSE, kAYColorConversionRGBDefault);
    
    glVertexAttribPointer(vPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(vTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
    
    [firstInputFramebuffer unlock];
    
    //导出数据
    CVPixelBufferLockBaseAddress(outputYPixelBuffer, 0);
    GLubyte *outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputYPixelBuffer, 0);
    memcpy(self.outputYData, outputBuffer, self.outputWidth * self.outputHeight);
    CVPixelBufferUnlockBaseAddress(outputYPixelBuffer, 0);

    CVPixelBufferLockBaseAddress(outputUPixelBuffer, 0);
    outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputUPixelBuffer, 0);
    memcpy(self.outputUData, outputBuffer, self.outputWidth * self.outputHeight / 4);
    CVPixelBufferUnlockBaseAddress(outputUPixelBuffer, 0);
    
    CVPixelBufferLockBaseAddress(outputVPixelBuffer, 0);
    outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputVPixelBuffer, 0);
    memcpy(self.outputVData, outputBuffer, self.outputWidth * self.outputHeight / 4);
    CVPixelBufferUnlockBaseAddress(outputVPixelBuffer, 0);
    
}

- (void)setOutputWithYData:(void *)YData uData:(void *)uData vData:(void *)vData width:(int)width height:(int)height{
    
    // 清空GL资源
    if (self.outputWidth != width || self.outputHeight != height) {
        [self releaseGLResources];
    }
    
    self.outputYData = YData;
    self.outputUData = uData;
    self.outputVData = vData;
    self.outputWidth = width;
    self.outputHeight = height;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)setInputSize:(CGSize)newSize {
    
}

- (void)setInputFramebuffer:(AYGPUImageFramebuffer *)newInputFramebuffer {
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)newFrameReady {
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self renderAtInternalSize];
    });
}

- (void)releaseGLResources {
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (yFrameBuffer) {
            glDeleteFramebuffers(1, &yFrameBuffer);
            yFrameBuffer = 0;
        }
        
        if (uFrameBuffer) {
            glDeleteFramebuffers(1, &uFrameBuffer);
            uFrameBuffer = 0;
        }
        
        if (vFrameBuffer) {
            glDeleteFramebuffers(1, &vFrameBuffer);
            vFrameBuffer = 0;
        }
        
        if (outputYPixelBuffer)
        {
            CFRelease(outputYPixelBuffer);
            outputYPixelBuffer = NULL;
        }
        
        if (outputUPixelBuffer)
        {
            CFRelease(outputUPixelBuffer);
            outputUPixelBuffer = NULL;
        }
        
        if (outputVPixelBuffer)
        {
            CFRelease(outputVPixelBuffer);
            outputVPixelBuffer = NULL;
        }
        
        if (yTextureRef)
        {
            CFRelease(yTextureRef);
            yTextureRef = NULL;
        }
        
        if (uTextureRef)
        {
            CFRelease(uTextureRef);
            uTextureRef = NULL;
        }
        
        if (vTextureRef)
        {
            CFRelease(vTextureRef);
            vTextureRef = NULL;
        }
    });
}

- (void)dealloc {
    [self releaseGLResources];
}

@end
