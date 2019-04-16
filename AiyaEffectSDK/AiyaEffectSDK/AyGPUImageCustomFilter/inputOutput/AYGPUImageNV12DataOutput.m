//
//  AYGPUImageNV12DataOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/26.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageNV12DataOutput.h"

#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"

NSString *const kAYLuminanceConversionFragmentShaderString = SHADER_STRING
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

NSString *const kAYChrominanceConversionFragmentShaderString = SHADER_STRING
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
     gl_FragColor = vec4(yuv.y+0.5, yuv.z+0.5, 0, 0);
 }
);

// BT.601 full range.
GLfloat kAYColorConversionRGBDefault[] = {
    0.298,       -0.169,        0.501,
    0.587,       -0.333,       -0.420,
    0.114,       0.502,        -0.082
};

@interface AYGPUImageNV12DataOutput (){
    AYGPUImageFramebuffer *firstInputFramebuffer;
    
    AYGLProgram *luminanceProgram;
    GLint luminancePositionAttribute, luminanceTextureCoordinateAttribute;
    GLint luminanceInputTextureUniform;
    GLint luminanceColorConversionUniform;
    
    AYGLProgram *chrominanceProgram;
    GLint chrominancePositionAttribute, chrominanceTextureCoordinateAttribute;
    GLint chrominanceInputTextureUniform;
    GLint chrominanceColorConversionUniform;

    GLuint luminanceFrameBuffer;
    GLuint chrominanceFrameBuffer;
    
    CVOpenGLESTextureRef luminanceTextureRef;
    CVOpenGLESTextureRef chrominanceTextureRef;

    CVPixelBufferRef outputPixelBuffer;
}

@property (nonatomic, weak) AYGPUImageContext *context;
@property (nonatomic, assign) CGSize inputSize;

@property (nonatomic, assign) CVPixelBufferRef outputBuffer;
@property (nonatomic, assign) void* outputYData;
@property (nonatomic, assign) void* outputUVData;
@property (nonatomic, assign) int outputWidth;
@property (nonatomic, assign) int outputHeight;

@end

@implementation AYGPUImageNV12DataOutput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _context = context;
    
    runAYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        luminanceProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAYGPUImagePassthroughFragmentShaderString];
        
        if (!luminanceProgram.initialized)
        {
            if (![luminanceProgram link])
            {
                NSString *progLog = [luminanceProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [luminanceProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [luminanceProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                luminanceProgram = nil;
            }
        }
        
        luminancePositionAttribute = [luminanceProgram attributeIndex:@"position"];
        luminanceTextureCoordinateAttribute = [luminanceProgram attributeIndex:@"inputTextureCoordinate"];
        luminanceInputTextureUniform = [luminanceProgram uniformIndex:@"inputImageTexture"];
        luminanceColorConversionUniform = [luminanceProgram uniformIndex:@"colorConversionMatrix"];
        
        chrominanceProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAYGPUImagePassthroughFragmentShaderString];
        
        if (!chrominanceProgram.initialized)
        {
            if (![chrominanceProgram link])
            {
                NSString *progLog = [chrominanceProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [chrominanceProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [chrominanceProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                chrominanceProgram = nil;
            }
        }
        
        chrominancePositionAttribute = [chrominanceProgram attributeIndex:@"position"];
        chrominanceTextureCoordinateAttribute = [chrominanceProgram attributeIndex:@"inputTextureCoordinate"];
        chrominanceInputTextureUniform = [chrominanceProgram uniformIndex:@"inputImageTexture"];
        chrominanceColorConversionUniform = [chrominanceProgram uniformIndex:@"colorConversionMatrix"];
    });
    
    return self;
}

- (void)createoutputPixelBufferWithWidth:(GLsizei)width height:(GLsizei)height{
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attrs, &outputPixelBuffer);
    
    CFRelease(attrs);
    CFRelease(empty);
}

- (void)createLuminanceFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    glGenFramebuffers(1, &luminanceFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, luminanceFrameBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self.context coreVideoTextureCache], outputPixelBuffer, NULL, GL_TEXTURE_2D, GL_RED_EXT, width, height, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &luminanceTextureRef);
    
    glBindTexture(CVOpenGLESTextureGetTarget(luminanceTextureRef), CVOpenGLESTextureGetName(luminanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(luminanceTextureRef), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)createChrominanceFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    glGenFramebuffers(1, &chrominanceFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, chrominanceFrameBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self.context coreVideoTextureCache], outputPixelBuffer, NULL, GL_TEXTURE_2D, GL_RG_EXT, width, height, GL_RG_EXT, GL_UNSIGNED_BYTE, 0, &chrominanceTextureRef);
    
    glBindTexture(CVOpenGLESTextureGetTarget(chrominanceTextureRef), CVOpenGLESTextureGetName(chrominanceTextureRef));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(chrominanceTextureRef), 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}


#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    
    //==========> 绘制luminance数据
    [luminanceProgram use];
    
    if (!luminanceFrameBuffer) {
        [self createLuminanceFramebufferWithWidth:self.outputWidth height:self.outputHeight];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, luminanceFrameBuffer);
    
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
    glUniform1i(luminanceInputTextureUniform, 4);
    
    glUniformMatrix3fv(luminanceColorConversionUniform, 1, GL_FALSE, kAYColorConversionRGBDefault);
    
    glVertexAttribPointer(luminancePositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(luminanceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,[AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //==========> 绘制chrominance数据
    
    [chrominanceProgram use];
    
    if (!chrominanceFrameBuffer) {
        [self createChrominanceFramebufferWithWidth:self.outputWidth height:self.outputHeight];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, chrominanceFrameBuffer);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(chrominanceInputTextureUniform, 4);
    
    glVertexAttribPointer(chrominancePositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(chrominanceTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glFinish();
    
    [firstInputFramebuffer unlock];
    
    //导出数据
    CVPixelBufferLockBaseAddress(outputPixelBuffer, 0);

    if (self.outputBuffer) {
        CVPixelBufferLockBaseAddress(self.outputBuffer, 0);

        GLubyte *targetBuffer = CVPixelBufferGetBaseAddressOfPlane(self.outputBuffer, 0);
        GLubyte *outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
        memcpy(targetBuffer, outputBuffer, self.outputWidth * self.outputHeight);
        
        targetBuffer = CVPixelBufferGetBaseAddressOfPlane(self.outputBuffer, 1);
        outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
        memcpy(targetBuffer, outputBuffer, self.outputWidth * self.outputHeight / 2);
    
        CVPixelBufferUnlockBaseAddress(self.outputBuffer, 0);
    } else {
        
        GLubyte *outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 0);
        memcpy(self.outputYData, outputBuffer, self.outputWidth * self.outputHeight);
        
        outputBuffer = CVPixelBufferGetBaseAddressOfPlane(outputPixelBuffer, 1);
        memcpy(self.outputUVData, outputBuffer, self.outputWidth * self.outputHeight / 2);
    }
    
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer, 0);
}

- (void)setOutputWithYData:(void *)YData uvData:(void *)uvData width:(int)width height:(int)height{
    self.outputBuffer = NULL;
    
    // 清空GL资源
    if (self.outputWidth != width || self.outputHeight != height) {
        [self releaseGLResources];
    }
    
    self.outputYData = YData;
    self.outputUVData = uvData;
    self.outputWidth = width;
    self.outputHeight = height;
}

- (void)setOutputWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    self.outputYData = NULL;
    self.outputUVData = NULL;
    
    // 清空GL资源
    if (self.outputWidth != (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) || self.outputHeight != (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)) {
        [self releaseGLResources];
    }
    
    self.outputBuffer = pixelBuffer;
    self.outputWidth = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    self.outputHeight = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
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
        
        if (luminanceFrameBuffer) {
            glDeleteFramebuffers(1, &luminanceFrameBuffer);
            luminanceFrameBuffer = 0;
        }
        
        if (chrominanceFrameBuffer) {
            glDeleteFramebuffers(1, &chrominanceFrameBuffer);
            chrominanceFrameBuffer = 0;
        }
        
        if (outputPixelBuffer)
        {
            CFRelease(outputPixelBuffer);
            outputPixelBuffer = NULL;
        }
        
        if (luminanceTextureRef)
        {
            CFRelease(luminanceTextureRef);
            luminanceTextureRef = NULL;
        }
        
        if (chrominanceTextureRef)
        {
            CFRelease(chrominanceTextureRef);
            chrominanceTextureRef = NULL;
        }
    });
}

- (void)dealloc {
    [self releaseGLResources];
}

@end
