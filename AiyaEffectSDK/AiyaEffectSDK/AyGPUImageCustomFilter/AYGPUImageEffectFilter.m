//
//  AYGPUImageEffectFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageEffectFilter.h"

#if AY_ENABLE_EFFECT
#import "AyEffect.h"
#endif

#if AY_ENABLE_EFFECT
@interface AYGPUImageEffectFilter() <AyEffectDelegate>{
#else
@interface AYGPUImageEffectFilter() {
#endif
    GLuint depthRenderbuffer;
}

#if AY_ENABLE_EFFECT
@property (nonatomic, strong) AyEffect *effect;
#endif

@property (nonatomic, assign) NSInteger currentPlayCount;

@end

@implementation AYGPUImageEffectFilter

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString{
    if (!(self = [super initWithContext:context vertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString])){
        return nil;
    }
    
#if AY_ENABLE_EFFECT
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self createRBO];

        _effect = [[AyEffect alloc] init];
        _effect.delegate = self;
        [self.effect initGLResource];
    });
    
#endif
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;{
    
    [self.context useAsCurrentContext];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];
    
#if AY_ENABLE_EFFECT
    //------------->绘制图像<--------------//
    // 打开深度Buffer 打开深度测试
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, outputFramebuffer.size.width, outputFramebuffer.size.height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    
    if (_faceData && *_faceData) {
        [self.effect setFaceData:*_faceData];
    }
    
    [self.effect processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    
    // 关闭深度Buffer 关闭深度测试
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, 0);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    //------------->绘制图像<--------------//
#endif
    
    [firstInputFramebuffer unlock];
}

- (void)setEffectPath:(NSString *)effectPath{
    _effectPath = effectPath;
    
#if AY_ENABLE_EFFECT
    [self.effect setEffectPath:effectPath];
#endif

}

- (void)setEffectPlayCount:(NSUInteger)effectPlayCount{
    _effectPlayCount = effectPlayCount;
    self.currentPlayCount = 0;
}

#if AY_ENABLE_EFFECT
- (void)effectMessageWithType:(NSInteger)type ret:(NSInteger)ret info:(NSString *)info {
    if (!self.effectPath || [self.effectPath isEqualToString:@""]){
        
    }else if ([@"AY_EFFECTS_END" isEqualToString:info]) {//已经渲染完成一遍
        self.currentPlayCount ++;
        if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount){
            [self setEffectPath:@""];
            if (self.delegate) {
                [self.delegate playEnd];
            }
        }
    }else if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount) {//已经播放完成
        [self setEffectPath:@""];
        if (self.delegate) {
            [self.delegate playEnd];
        }
    }
}
#endif

- (void)pause{
#if AY_ENABLE_EFFECT
    [self.effect pauseProcess];
#endif
}

- (void)resume{
#if AY_ENABLE_EFFECT
    [self.effect resumeProcess];
#endif
}

#if AY_ENABLE_EFFECT
- (void)createRBO{
    glGenRenderbuffers(1, &depthRenderbuffer);
}

- (void)destoryRBO{
    if (depthRenderbuffer){
        glDeleteRenderbuffers(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}

- (void)dealloc{
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self.effect releaseGLtContext];
        [self destoryRBO];
    });
}
#endif

@end
