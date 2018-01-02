//
//  CameraDataProcess.m
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "CameraDataProcess.h"
#import "OpenglHelper.h"

static const NSString * kVertexShaderString =
@"attribute vec4 position;\n"
"attribute vec2 inputTextureCoordinate;\n"
"varying mediump vec2 v_texCoord;\n"
"uniform mediump mat4 transformMatrix;\n"
"void main()\n"
"{\n"
"    gl_Position = transformMatrix * position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"}\n";

static const NSString *kFragmentShaderString =
@"precision lowp float;\n"
"uniform sampler2D inputTexture;\n"
"varying highp vec2 v_texCoord;\n"
"void main()\n"
"{\n"
"    gl_FragColor = texture2D(inputTexture, v_texCoord);\n"
"}\n";


static const NSString * kYUVFragmentShaderString =
@"precision lowp float;\n"
"varying highp vec2 v_texCoord;\n"
"uniform sampler2D luminanceTexture;\n"
"uniform sampler2D chrominanceTexture;\n"
"uniform mediump mat3 colorConversionMatrix;\n"
"void main()\n"
"{\n"
"mediump vec3 yuv;\n"
"    lowp vec3 rgb;\n"
"    yuv.x = texture2D(luminanceTexture, v_texCoord).r;\n"
"    yuv.yz = texture2D(chrominanceTexture, v_texCoord).ra - vec2(0.5, 0.5);\n"
"    rgb = colorConversionMatrix * yuv;\n"
"    gl_FragColor = vec4(rgb, 1);\n"
"}\n";

// BT.601 full range.
static const GLfloat kAYColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

static const GLfloat squareVertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

static const GLfloat verticalFlipTextureCoordinates[] = {
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f,  0.0f,
    1.0f,  0.0f,
};

static const GLfloat noRotationTextureCoordinates[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
};

@interface CameraDataProcess () {
    OpenglHelper *glHelper;

    GLuint inputFrameBuffer;
    GLuint inputTexture;
    
    GLuint inputProgram;
    GLuint positionAttribute, textureCoordinateAttribute;
    GLint luminanceTextureUniform, chrominanceTextureUniform;
    GLint conversionMatrixUniform;
    GLint transformMatrixUniform;
    
    GLuint outputFrameBuffer;
    CVPixelBufferRef outputCVPixelBuffer;
    CVOpenGLESTextureRef outputTextureRef;
    CMSampleBufferRef outputSampleBuffer;
    
    GLuint outputProgram;
    GLuint positionAttribute2, textureCoordinateAttribute2;
    GLint inputTextureUniform;
    GLint transformMatrixUniform2;
    
    GLuint luminanceTexture;
    GLuint chrominanceTexture;

}

@property (nonatomic, assign) int inputWidth;
@property (nonatomic, assign) int inputHeight;

@end

@implementation CameraDataProcess

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initGL];
    }
    return self;
}

- (void)initGL{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        glHelper = [OpenglHelper share];
        [glHelper useAsCurrentContext];
        
        inputProgram = [glHelper createProgramWithVert:kVertexShaderString frag:kYUVFragmentShaderString];
        positionAttribute = glGetAttribLocation(inputProgram, [@"position" UTF8String]);
        textureCoordinateAttribute = glGetAttribLocation(inputProgram, [@"inputTextureCoordinate" UTF8String]);
        luminanceTextureUniform = glGetUniformLocation(inputProgram, [@"luminanceTexture" UTF8String]);
        chrominanceTextureUniform = glGetUniformLocation(inputProgram, [@"chrominanceTexture" UTF8String]);
        conversionMatrixUniform = glGetUniformLocation(inputProgram, [@"colorConversionMatrix" UTF8String]);
        transformMatrixUniform = glGetUniformLocation(inputProgram, [@"transformMatrix" UTF8String]);

        outputProgram = [glHelper createProgramWithVert:kVertexShaderString frag:kFragmentShaderString];
        positionAttribute2 = glGetAttribLocation(outputProgram, [@"position" UTF8String]);
        textureCoordinateAttribute2 = glGetAttribLocation(outputProgram, [@"inputTextureCoordinate" UTF8String]);
        inputTextureUniform = glGetUniformLocation(outputProgram, [@"inputTexture" UTF8String]);
        transformMatrixUniform2 = glGetUniformLocation(outputProgram, [@"transformMatrix" UTF8String]);
    });
}

- (CMSampleBufferRef)process:(CMSampleBufferRef)sampleBuffer{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
// ----------绘制YUV数据 绘制开始----------
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        int width = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
        int height = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
        
        int inputWidth = height;
        int inputHeight = width;
        if (inputWidth != self.inputWidth || inputHeight != self.inputHeight) {
            [self releaseGLResources];
            self.inputWidth = inputWidth;
            self.inputHeight = inputHeight;
        }
        
        if (!inputFrameBuffer) {
            [self createInputFrameBufferWithWidth:inputWidth height:inputHeight];
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, inputFrameBuffer);
        glViewport(0, 0, inputWidth, inputHeight);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glUseProgram(inputProgram);
        
        // Y-plane
        glActiveTexture(GL_TEXTURE1);

        if (!luminanceTexture) {
            glGenTextures(1, &luminanceTexture);
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }else {
            glBindTexture(GL_TEXTURE_2D, luminanceTexture);
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        void *yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (int)width, (int)height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yPlane);
        
        glUniform1i(luminanceTextureUniform, 1);

        // UV-plane
        glActiveTexture(GL_TEXTURE2);

        if (!chrominanceTexture) {
            glGenTextures(1, &chrominanceTexture);
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }else {
            glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        }

        void *uvPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, (int)width / 2, (int)height / 2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uvPlane);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        glUniform1i(chrominanceTextureUniform, 2);
        glActiveTexture(GL_TEXTURE0);
        
        // transfrom
        CATransform3D transform3D = CATransform3DMakeRotation(M_PI_2, 0, 0, 1);
        GLfloat transformMatrix[16];
        transformMatrix[0] = (GLfloat)transform3D.m11;
        transformMatrix[1] = (GLfloat)transform3D.m21;
        transformMatrix[2] = (GLfloat)transform3D.m31;
        transformMatrix[3] = (GLfloat)transform3D.m41;
        transformMatrix[4] = (GLfloat)transform3D.m12;
        transformMatrix[5] = (GLfloat)transform3D.m22;
        transformMatrix[6] = (GLfloat)transform3D.m32;
        transformMatrix[7] = (GLfloat)transform3D.m42;
        transformMatrix[8] = (GLfloat)transform3D.m13;
        transformMatrix[9] = (GLfloat)transform3D.m23;
        transformMatrix[10] = (GLfloat)transform3D.m33;
        transformMatrix[11] = (GLfloat)transform3D.m43;
        transformMatrix[12] = (GLfloat)transform3D.m14;
        transformMatrix[13] = (GLfloat)transform3D.m24;
        transformMatrix[14] = (GLfloat)transform3D.m34;
        transformMatrix[15] = (GLfloat)transform3D.m44;
        
        glVertexAttribPointer(positionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        
        if (_mirror) {
            glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, verticalFlipTextureCoordinates);
        }else {
            glVertexAttribPointer(textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
        }
        glUniformMatrix4fv(transformMatrixUniform, 1, GL_FALSE, transformMatrix);
        glUniformMatrix3fv(conversionMatrixUniform, 1, GL_FALSE, kAYColorConversion601FullRangeDefault);

        glEnableVertexAttribArray(positionAttribute);
        glEnableVertexAttribArray(textureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
// ----------绘制YUV数据 绘制结束----------

        // 回调纹理数据
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraDataProcessWithTexture:width:height:)]) {
            inputTexture = [self.delegate cameraDataProcessWithTexture:inputTexture width:height height:width];
        }
     
// ----------绘制BGRA格式的纹理到CMSampleBuffer中 绘制开始----------
        int outputWidth = width;
        int outputHeight = height;
        
        if (!outputFrameBuffer) {
            [self createOutputFrameBufferWithWidth:outputWidth height:outputHeight];
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, outputFrameBuffer);
        glViewport(0, 0, outputWidth, outputHeight);
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glUseProgram(outputProgram);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputTexture);
        glUniform1i(inputTextureUniform, 1);

        transform3D = CATransform3DMakeRotation(-M_PI_2, 0, 0, 1);
        transformMatrix[0] = (GLfloat)transform3D.m11;
        transformMatrix[1] = (GLfloat)transform3D.m21;
        transformMatrix[2] = (GLfloat)transform3D.m31;
        transformMatrix[3] = (GLfloat)transform3D.m41;
        transformMatrix[4] = (GLfloat)transform3D.m12;
        transformMatrix[5] = (GLfloat)transform3D.m22;
        transformMatrix[6] = (GLfloat)transform3D.m32;
        transformMatrix[7] = (GLfloat)transform3D.m42;
        transformMatrix[8] = (GLfloat)transform3D.m13;
        transformMatrix[9] = (GLfloat)transform3D.m23;
        transformMatrix[10] = (GLfloat)transform3D.m33;
        transformMatrix[11] = (GLfloat)transform3D.m43;
        transformMatrix[12] = (GLfloat)transform3D.m14;
        transformMatrix[13] = (GLfloat)transform3D.m24;
        transformMatrix[14] = (GLfloat)transform3D.m34;
        transformMatrix[15] = (GLfloat)transform3D.m44;
        glUniformMatrix4fv(transformMatrixUniform2, 1, GL_FALSE, transformMatrix);
        
        glEnableVertexAttribArray(positionAttribute2);
        glEnableVertexAttribArray(textureCoordinateAttribute2);
        
        glVertexAttribPointer(positionAttribute2, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(textureCoordinateAttribute2, 2, GL_FLOAT, 0, 0, noRotationTextureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

        glFinish();
        
        //CVPixelBufferRef 封装成 CMSampleBufferRef
        CMFormatDescriptionRef outputFormatDescription = NULL;
        CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, outputCVPixelBuffer, &outputFormatDescription );
        CMSampleTimingInfo timingInfo = {0,};
        timingInfo.duration = kCMTimeInvalid;
        timingInfo.decodeTimeStamp = kCMTimeInvalid;
        timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, outputCVPixelBuffer, true, NULL, NULL, outputFormatDescription, &timingInfo, &outputSampleBuffer );
        CFRelease(outputFormatDescription);
        
// ----------绘制BGRA格式的纹理到CMSampleBuffer中 绘制结束----------
    });
    return outputSampleBuffer;
}

- (void)createInputFrameBufferWithWidth:(int)width height:(int)height{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        glGenFramebuffers(1, &inputFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, inputFrameBuffer);
        
        glGenTextures(1, &inputTexture);
        glBindTexture(GL_TEXTURE_2D, inputTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, inputTexture, 0);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyInputFramebuffer{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        if (inputFrameBuffer){
            glDeleteFramebuffers(1, &inputFrameBuffer);
            inputFrameBuffer = 0;
        }
        
        if (inputTexture) {
            glDeleteTextures(1, &inputTexture);
            inputTexture = 0;
        }
        
        if (luminanceTexture) {
            glDeleteTextures(1, &luminanceTexture);
            luminanceTexture = 0;
        }

        if (chrominanceTexture) {
            glDeleteTextures(1, &chrominanceTexture);
            chrominanceTexture = 0;
        }
    });
}

- (void)createOutputFrameBufferWithWidth:(int)width height:(int)height{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];

        glGenFramebuffers(1, &outputFrameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, outputFrameBuffer);
        
        CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
        
        CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &outputCVPixelBuffer);
        
        if (err){
            NSLog(@"Error at CVPixelBufferCreate %d", err);
        }
        
        CFRelease(attrs);
        CFRelease(empty);
        
        CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [glHelper coreVideoTextureCache], outputCVPixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &outputTextureRef);
        glBindTexture(CVOpenGLESTextureGetTarget(outputTextureRef), CVOpenGLESTextureGetName(outputTextureRef));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(outputTextureRef), 0);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyOutputFramebuffer{
    runSynchronouslyOnOpenglHelperContextQueue(^{
        [glHelper useAsCurrentContext];
        
        if (outputFrameBuffer){
            glDeleteFramebuffers(1, &outputFrameBuffer);
            outputFrameBuffer = 0;
        }
        
        if (outputTextureRef){
            CFRelease(outputTextureRef);
            outputTextureRef = NULL;
        }
        
        if (outputCVPixelBuffer) {
            CFRelease(outputCVPixelBuffer);
            outputCVPixelBuffer = NULL;
        }
    });
}

- (void)releaseGLResources{
    [self destroyInputFramebuffer];
    [self destroyOutputFramebuffer];
}

- (void)dealloc{
    [self releaseGLResources];
}

@end
