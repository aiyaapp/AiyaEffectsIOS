//
//  VideoEffectHandler.m
//  LLSimpleCameraExample
//
//  Created by 汪洋 on 2017/9/30.
//  Copyright © 2017年 Ömer Faruk Gül. All rights reserved.
//

#import "VideoEffectHandlerView.h"
#import "OpenglHelper.h"
#import <CoreVideo/CoreVideo.h>

//----------哎吖科技添加 开始----------
#import <AiyaEffectSDK/AiyaEffectSDK.h>
//----------哎吖科技添加 结束----------

static const NSString * kVertexShaderString =
@"attribute vec4 position;\n"
"attribute vec2 inputTextureCoordinate;\n"
"varying mediump vec2 v_texCoord;\n"
"void main()\n"
"{\n"
"    gl_Position = position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"}\n";

static const NSString * kTransformVertexShaderString =
@"attribute vec4 position;\n"
"attribute vec2 inputTextureCoordinate;\n"
"varying mediump vec2 v_texCoord;\n"
"uniform mediump mat4 transformMatrixUniform;\n"
"void main()\n"
"{\n"
"    gl_Position = transformMatrixUniform * position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"}\n";

static const NSString * kYUVFullRangeConversionForLAFragmentShaderString =
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

static const NSString *kDisplayFragmentShaderString =
@"precision lowp float;\n"
"uniform sampler2D mTexture;\n"
"varying highp vec2 v_texCoord;\n"
"void main()\n"
"{\n"
"    gl_FragColor = texture2D(mTexture, v_texCoord);\n"
"}\n";


// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601 full range.
GLfloat kAYColorConversion601FullRangeDefault[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};

GLfloat *kAYColorConversion601FullRange = kAYColorConversion601FullRangeDefault;

@interface VideoEffectHandlerView(){
    const GLfloat *_preferredConversion;
    GLuint luminanceTexture, chrominanceTexture;
    
    CAEAGLLayer *glLayer;
    
    GLuint videoCameraFramebuffer, videoCameraTexture;
    GLuint videoCameraProgram;
    GLint yuvConversionPositionAttribute, yuvConversionTextureCoordinateAttribute;
    GLint yuvConversionLuminanceTextureUniform, yuvConversionChrominanceTextureUniform;
    GLint yuvConversionMatrixUniform;
    GLint transformMatrixUniform;
    
    GLuint displayRenderbuffer, displayFramebuffer;
    GLint backingWidth, backingHeight;
    GLuint displayProgram;
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;
    
    GLuint outputFramebuffer, outputFrameTexture;
    CVPixelBufferRef outputCVPixelBuffer;
    CVOpenGLESTextureRef outputTextureRef;
    
    GLuint cvPixelBufferTexture;
    
    OpenglHelper *glHelper;
    
    EAGLContext *contextB;
    
//----------哎吖科技添加 开始----------
    AYShortVideoEffectHandler *effectHandler;
//----------哎吖科技添加 结束----------

    NSInteger _efffectType;
    BOOL updateEffectType;
}

@end

@implementation VideoEffectHandlerView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commitInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commitInit];
    }
    return self;
}

- (void)commitInit{
        
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    
    self.opaque = YES;
    self.hidden = NO;
    glLayer = (CAEAGLLayer *)self.layer;
    glLayer.opaque = YES;
    glLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    glHelper = [[OpenglHelper alloc] init];
    [glHelper useAsCurrentContext];

    videoCameraProgram = [glHelper createProgramWithVert:kTransformVertexShaderString frag:kYUVFullRangeConversionForLAFragmentShaderString];

    yuvConversionPositionAttribute = glGetAttribLocation(videoCameraProgram, [@"position" UTF8String]);
    yuvConversionTextureCoordinateAttribute = glGetAttribLocation(videoCameraProgram, [@"inputTextureCoordinate" UTF8String]);
    yuvConversionLuminanceTextureUniform = glGetUniformLocation(videoCameraProgram, [@"luminanceTexture" UTF8String]);
    yuvConversionChrominanceTextureUniform = glGetUniformLocation(videoCameraProgram, [@"chrominanceTexture" UTF8String]);
    yuvConversionMatrixUniform = glGetUniformLocation(videoCameraProgram, [@"colorConversionMatrix" UTF8String]);
    transformMatrixUniform = glGetUniformLocation(videoCameraProgram, [@"transformMatrixUniform" UTF8String]);

    //初始化GL显示
    displayProgram = [glHelper createProgramWithVert:kVertexShaderString frag:kDisplayFragmentShaderString];
    displayPositionAttribute = glGetAttribLocation(displayProgram, [@"position" UTF8String]);
    displayTextureCoordinateAttribute = glGetAttribLocation(displayProgram, [@"inputTextureCoordinate" UTF8String]);
    displayInputTextureUniform = glGetUniformLocation(displayProgram, [@"mTexture" UTF8String]);
    
    glEnableVertexAttribArray(yuvConversionPositionAttribute);
    glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
}

- (void)setEffectType:(NSInteger)effectType{
    _efffectType = effectType;
    updateEffectType = YES;
}

#pragma mark 处理视频数据
- (CMSampleBufferRef)process:(CMSampleBufferRef)sampleBuffer transformMatrix:(GLfloat *)transformMatrix outputSize:(CGSize)outputSize{
    _preferredConversion = kAYColorConversion601FullRange;

    [glHelper useAsCurrentContext];
    
    //渲染yuv数据
    if (!videoCameraFramebuffer) {
        [self createVideoCameraFramebufferWithWidth:outputSize.width height:outputSize.height];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, videoCameraFramebuffer);
    glViewport(0, 0,outputSize.width ,outputSize.height );
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(videoCameraProgram);
    
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
    
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    size_t planeDataWidth = CVPixelBufferGetBytesPerRowOfPlane(cameraFrame, 0);
    size_t planeHeight = CVPixelBufferGetHeightOfPlane(cameraFrame, 0);
    
    // Y-plane
    if (!luminanceTexture) {
        glGenTextures(1, &luminanceTexture);
        glBindTexture(GL_TEXTURE_2D, luminanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, luminanceTexture);

    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    void *yPlane = CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, (int)planeDataWidth, (int)planeHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yPlane);
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    glActiveTexture(GL_TEXTURE0);

    glUniform1i(yuvConversionLuminanceTextureUniform, 1);
    
    // UV-plane
    if (!chrominanceTexture) {
        glGenTextures(1, &chrominanceTexture);
        glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    
    // >> 渲染 YUV数据
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, chrominanceTexture);
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    void *uvPlane = CVPixelBufferGetBaseAddressOfPlane(cameraFrame, 1);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, (int)planeDataWidth / 2, (int)planeHeight / 2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uvPlane);
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    glActiveTexture(GL_TEXTURE0);

    glUniform1i(yuvConversionChrominanceTextureUniform, 2);
    
    glUniformMatrix3fv(yuvConversionMatrixUniform, 1, GL_FALSE, _preferredConversion);
    glUniformMatrix4fv(transformMatrixUniform, 1, GL_FALSE, transformMatrix);
    
    glVertexAttribPointer(yuvConversionPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(yuvConversionTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, verticalFlipTextureCoordinates);
    
    glEnableVertexAttribArray(yuvConversionPositionAttribute);
    glEnableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(yuvConversionPositionAttribute);
    glDisableVertexAttribArray(yuvConversionTextureCoordinateAttribute);
    
//----------哎吖科技添加 开始----------
    if (!effectHandler) {
        effectHandler = [[AYShortVideoEffectHandler alloc] init];
    }

    if (updateEffectType) {
        [effectHandler setType:_efffectType];

        updateEffectType = NO;
    }

    [effectHandler processWithTexture:videoCameraTexture width:outputSize.width height:outputSize.height];
//----------哎吖科技添加 开始----------

    // >> 渲染 导出原始BGRA数据
    if (!outputFramebuffer) {
        [self createOutputFramebufferWithWidth:outputSize.width height:outputSize.height];
    }
    glBindFramebuffer(GL_FRAMEBUFFER, outputFramebuffer);
    glViewport(0, 0, outputSize.width, outputSize.height);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(displayProgram);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, videoCameraTexture);
    glUniform1i(displayInputTextureUniform, 1);
    
    glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, verticalFlipTextureCoordinates);
    
    glEnableVertexAttribArray(displayPositionAttribute);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
    
    //CVPixelBufferRef 封装成 CMSampleBufferRef
    CMSampleBufferRef tempSamepleBuffer = NULL;
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, outputCVPixelBuffer, &outputFormatDescription );
    CMSampleTimingInfo timingInfo = {0,};
    timingInfo.duration = kCMTimeInvalid;
    timingInfo.decodeTimeStamp = kCMTimeInvalid;
    timingInfo.presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, outputCVPixelBuffer, true, NULL, NULL, outputFormatDescription, &timingInfo, &tempSamepleBuffer );
    CFRelease(outputFormatDescription);
    
    // 渲染 >> BGRA格式的CVPixelBuffer 到屏幕上
    if (!displayFramebuffer) {
        [self createDisplayFramebuffer];
    }
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(displayProgram);
    
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(outputSize.width, outputSize.height), CGRectMake(0, 0, backingWidth, backingHeight));
    
    CGFloat heightScaling, widthScaling;
    
    //图像填充方式一:拉伸
    //    widthScaling = 1.0;
    //    heightScaling = 1.0;
    
    //图像填充方式二:保持宽高比
    widthScaling = insetRect.size.width / backingWidth;
    heightScaling = insetRect.size.height / backingHeight;
    
    //图像填充方式三:保持宽高比同时填满整个屏幕
    //    widthScaling = backingHeight / insetRect.size.height;
    //    heightScaling = backingWidth / insetRect.size.width;
    
    GLfloat displaySquareVertices[8] ;
    displaySquareVertices[0] = -widthScaling;
    displaySquareVertices[1] = -heightScaling;
    displaySquareVertices[2] = widthScaling;
    displaySquareVertices[3] = -heightScaling;
    displaySquareVertices[4] = -widthScaling;
    displaySquareVertices[5] = heightScaling;
    displaySquareVertices[6] = widthScaling;
    displaySquareVertices[7] = heightScaling;
    
    // 去掉对齐时的多余数据
    GLfloat cropRightTextureCoordinates[8];
    cropRightTextureCoordinates[0] = verticalFlipTextureCoordinates[0];
    cropRightTextureCoordinates[1] = verticalFlipTextureCoordinates[1];
    cropRightTextureCoordinates[2] = verticalFlipTextureCoordinates[2] - ((CGFloat)CVPixelBufferGetBytesPerRow(outputCVPixelBuffer) / 4.0f - (CGFloat)CVPixelBufferGetWidth(outputCVPixelBuffer)) / (CGFloat)CVPixelBufferGetWidth(outputCVPixelBuffer);
    cropRightTextureCoordinates[3] = verticalFlipTextureCoordinates[3];
    cropRightTextureCoordinates[4] = verticalFlipTextureCoordinates[4];
    cropRightTextureCoordinates[5] = verticalFlipTextureCoordinates[5];
    cropRightTextureCoordinates[6] = verticalFlipTextureCoordinates[6] - ((CGFloat)CVPixelBufferGetBytesPerRow(outputCVPixelBuffer) / 4.0f - (CGFloat)CVPixelBufferGetWidth(outputCVPixelBuffer)) / (CGFloat)CVPixelBufferGetWidth(outputCVPixelBuffer);
    cropRightTextureCoordinates[7] = verticalFlipTextureCoordinates[7];

    if (!cvPixelBufferTexture) {
        glGenTextures(1, &cvPixelBufferTexture);
        glBindTexture(GL_TEXTURE_2D, cvPixelBufferTexture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, cvPixelBufferTexture);
    CVPixelBufferLockBaseAddress(outputCVPixelBuffer, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)CVPixelBufferGetBytesPerRow(outputCVPixelBuffer) / 4, (int)CVPixelBufferGetHeight(outputCVPixelBuffer), 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(outputCVPixelBuffer));
    CVPixelBufferUnlockBaseAddress(outputCVPixelBuffer, 0);
    
    glUniform1i(displayInputTextureUniform, 1);
    
    glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, displaySquareVertices);
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, cropRightTextureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableVertexAttribArray(displayPositionAttribute);
    glDisableVertexAttribArray(displayTextureCoordinateAttribute);
    
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [[glHelper context] presentRenderbuffer:GL_RENDERBUFFER];
    
    return tempSamepleBuffer;
}


#pragma mark - 渲染相机YUV数据的Framebuffer
- (void)createVideoCameraFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    [glHelper useAsCurrentContext];
    
    glGenFramebuffers(1, &videoCameraFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, videoCameraFramebuffer);
    
    glGenTextures(1, &videoCameraTexture);
    glBindTexture(GL_TEXTURE_2D, videoCameraTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0,GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, videoCameraTexture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

- (void)destroyVideoCameraFramebuffer{
    [glHelper useAsCurrentContext];
    
    if (videoCameraFramebuffer){
        glDeleteFramebuffers(1, &videoCameraFramebuffer);
        videoCameraFramebuffer = 0;
    }
    
    if (videoCameraTexture) {
        glDeleteTextures(1, &videoCameraTexture);
        videoCameraTexture = 0;
    }
}

#pragma mark - 渲染到屏幕的Framebuffer

- (void)createDisplayFramebuffer;{
    [glHelper useAsCurrentContext];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    
    [[glHelper context] renderbufferStorage:GL_RENDERBUFFER fromDrawable:glLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    if ( (backingWidth == 0) || (backingHeight == 0) )
    {
        [self destroyDisplayFramebuffer];
        return;
    }
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
}

- (void)destroyDisplayFramebuffer;
{
    [glHelper useAsCurrentContext];
    
    if (displayFramebuffer)
    {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    
    if (displayRenderbuffer)
    {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
}

#pragma mark - 用于导出数据的Framebuffer
- (void)createOutputFramebufferWithWidth:(GLsizei)width height:(GLsizei)height{
    [glHelper useAsCurrentContext];
    
    glGenFramebuffers(1, &outputFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, outputFramebuffer);
    
    // 为了导出纹理数据 创建CVPixelBuffer
    CFDictionaryRef empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFMutableDictionaryRef attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVPixelBufferCreate(kCFAllocatorDefault, (int)width, (int)height, kCVPixelFormatType_32BGRA, attrs, &outputCVPixelBuffer);
    
    CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, glHelper.coreVideoTextureCache, outputCVPixelBuffer,NULL, GL_TEXTURE_2D, GL_RGBA, (int)width, (int)height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &outputTextureRef);
    
    CFRelease(attrs);
    CFRelease(empty);
    
    outputFrameTexture = CVOpenGLESTextureGetName(outputTextureRef);
    glBindTexture(CVOpenGLESTextureGetTarget(outputTextureRef), outputFrameTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, outputFrameTexture, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)destroyOutputFramebuffer{
    [glHelper useAsCurrentContext];
    
    if (outputFramebuffer){
        glDeleteFramebuffers(1, &outputFramebuffer);
        outputFramebuffer = 0;
    }
    
    if (outputTextureRef)
    {
        CFRelease(outputTextureRef);
        outputTextureRef = NULL;
    }
    
    if (outputCVPixelBuffer) {
        CFRelease(outputCVPixelBuffer);
        outputCVPixelBuffer = NULL;
    }
}

- (void)dealloc{
    if (cvPixelBufferTexture) {
        glDeleteTextures(1, &cvPixelBufferTexture);
        cvPixelBufferTexture = 0;
    }
    [self destroyVideoCameraFramebuffer];
    [self destroyDisplayFramebuffer];
    [self destroyOutputFramebuffer];
}
@end
