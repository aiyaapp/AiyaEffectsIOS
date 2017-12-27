//
//  AYShortVideoEffectHandler.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/2.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYShortVideoEffectHandler.h"
#import "AYGPUImageTextureInput.h"
#import "AYGPUImageTextureOutput.h"
#import "AYGPUImageRawDataInput.h"
#import "AYGPUImageRawDataOutput.h"

#if AY_ENABLE_SHORT_VIDEO
#import "AYGPUImageShortVideoFilter.h"
#endif

@interface AYShortVideoEffectHandler ()

@property (nonatomic, strong) AYGPUImageContext *glContext;
@property (nonatomic, strong) AYGPUImageTextureInput *textureInput;
@property (nonatomic, strong) AYGPUImageTextureOutput *textureOutput;
@property (nonatomic, strong) AYGPUImageRawDataInput *rawDataInput;
@property (nonatomic, strong) AYGPUImageRawDataOutput *rawDataOutput;

#if AY_ENABLE_SHORT_VIDEO
@property (nonatomic, strong) AYGPUImageShortVideoFilter *shortVideoFilter;
#endif

@property (nonatomic, assign) BOOL updateType;

@property (nonatomic, assign) AYGPUImageFilter *currentEffectFilter;

@end

@implementation AYShortVideoEffectHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
        _glContext = [[AYGPUImageContext alloc] init];
        
        _textureInput = [[AYGPUImageTextureInput alloc] initWithContext:_glContext];
        _textureOutput = [[AYGPUImageTextureOutput alloc] initWithContext:_glContext];
        _rawDataInput = [[AYGPUImageRawDataInput alloc] initWithContext:_glContext];
        _rawDataOutput = [[AYGPUImageRawDataOutput alloc] initWithContext:_glContext];
        

#if AY_ENABLE_SHORT_VIDEO
        _shortVideoFilter = [[AYGPUImageShortVideoFilter alloc] initWithContext:_glContext];
#endif
    }
    return self;
}

- (void)setType:(AY_SHORT_VIDEO_EFFECT_TYPE)type{
    _type = type;
    
    self.updateType = YES;
}

- (void)setVerticalFlip:(BOOL)verticalFlip{
    _verticalFlip = verticalFlip;
    
    self.textureInput.verticalFlip = verticalFlip;
    self.textureOutput.verticalFlip = verticalFlip;
}

- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height{
    // 获取当前绑定的FrameBuffer
    GLint bindingFrameBuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    GLint viewPoint[4];
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    if (self.updateType) {
#if AY_ENABLE_SHORT_VIDEO
        [self.shortVideoFilter setType:(NSUInteger)self.type];
        [self.shortVideoFilter reset];
        self.currentEffectFilter = self.shortVideoFilter;
#endif
        self.updateType = NO;
    }
    
    [self removeFilterTargers];
    
    if (self.currentEffectFilter) {
        [self.textureInput addTarget:self.currentEffectFilter];
        [self.currentEffectFilter addTarget:self.textureOutput];
    }else {
        [self.textureInput addTarget:self.textureOutput];
    }

    // 设置输出的Filter
    [self.textureOutput setOutputTexture:texture width:width height:height];
    
    // 设置输入的Filter, 同时开始处理纹理数据
    [self.textureInput processBGRADataWithTexture:texture width:width height:height];
    
    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
}

- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    // 获取当前绑定的FrameBuffer
    GLint bindingFrameBuffer;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    GLint viewPoint[4];
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    if (self.updateType) {
#if AY_ENABLE_SHORT_VIDEO
        [self.shortVideoFilter setType:(NSUInteger)self.type];
        [self.shortVideoFilter reset];
        self.currentEffectFilter = self.shortVideoFilter;
#endif
        self.updateType = NO;
    }
    
    [self removeFilterTargers];
    
    if (self.currentEffectFilter) {
        [self.rawDataInput addTarget:self.currentEffectFilter];
        [self.currentEffectFilter addTarget:self.rawDataOutput];
    }else {
        [self.rawDataInput addTarget:self.rawDataOutput];
    }
    
    // 设置输出的Filter
    [self.rawDataOutput setOutputCVPixelBuffer:pixelBuffer];
    
    // 设置输入的Filter, 同时开始处理BGRA数据
    [self.rawDataInput processBGRADataWithCVPixelBuffer:pixelBuffer];
    
    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
}

- (void)removeFilterTargers{
    [self.textureInput removeAllTargets];
    [self.rawDataInput removeAllTargets];
    
#if AY_ENABLE_SHORT_VIDEO
    [self.shortVideoFilter removeAllTargets];
#endif
}

- (void)dealloc{
    [self removeFilterTargers];
}

@end
