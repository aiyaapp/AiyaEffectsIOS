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

#if AY_ENABLE_SHORT_VIDEO
#import "AYGPUImageShortVideoFilter.h"
#endif

@interface AYShortVideoEffectHandler (){
    GLint bindingFrameBuffer;
    GLint viewPoint[4];
    NSMutableArray<NSNumber *>* vertexAttribEnableArray;
    NSInteger vertexAttribEnableArraySize;
}

@property (nonatomic, strong) AYGPUImageContext *glContext;
@property (nonatomic, strong) AYGPUImageTextureInput *textureInput;
@property (nonatomic, strong) AYGPUImageTextureOutput *textureOutput;

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
        vertexAttribEnableArraySize = 5;
        vertexAttribEnableArray = [NSMutableArray array];
        
        _glContext = [[AYGPUImageContext alloc] initWithNewGLContext];
        
        _textureInput = [[AYGPUImageTextureInput alloc] initWithContext:_glContext];
        _textureOutput = [[AYGPUImageTextureOutput alloc] initWithContext:_glContext];

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

- (void)setRotateMode:(AYGPUImageRotationMode)rotateMode{
    _rotateMode = rotateMode;
    
    self.textureInput.rotateMode = rotateMode;
    
    if (rotateMode == kAYGPUImageRotateLeft) {
        rotateMode = kAYGPUImageRotateRight;
    }else if (rotateMode == kAYGPUImageRotateRight) {
        rotateMode = kAYGPUImageRotateLeft;
    }
    
    self.textureOutput.rotateMode = rotateMode;
}
- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height{
    [self saveOpenGLState];
    
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
    [self.textureOutput setOutputWithBGRATexture:texture width:width height:height];
    
    // 设置输入的Filter, 同时开始处理纹理数据
    [self.textureInput processWithBGRATexture:texture width:width height:height];
    
    [self restoreOpenGLState];
}


/**
 保存opengl状态
 */
- (void)saveOpenGLState {
    // 获取当前绑定的FrameBuffer
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    // 获取viewpoint
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    // 获取顶点数据
    [vertexAttribEnableArray removeAllObjects];
    for (int x = 0 ; x < vertexAttribEnableArraySize; x++) {
        GLint vertexAttribEnable;
        glGetVertexAttribiv(x, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &vertexAttribEnable);
        if (vertexAttribEnable) {
            [vertexAttribEnableArray addObject:@(x)];
        }
    }
}

/**
 恢复opengl状态
 */
- (void)restoreOpenGLState {
    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    
    // 还原viewpoint
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
    
    // 还原顶点数据
    for (int x = 0 ; x < vertexAttribEnableArray.count; x++) {
        glEnableVertexAttribArray(vertexAttribEnableArray[x].intValue);
    }
}

- (void)removeFilterTargers{
    [self.textureInput removeAllTargets];
    
#if AY_ENABLE_SHORT_VIDEO
    [self.shortVideoFilter removeAllTargets];
#endif
}

- (void)dealloc{
    [self removeFilterTargers];
}

@end
