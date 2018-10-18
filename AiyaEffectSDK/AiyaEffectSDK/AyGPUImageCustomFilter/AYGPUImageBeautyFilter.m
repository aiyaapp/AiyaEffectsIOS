//
//  AYGPUImageBeautyFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/30.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageBeautyFilter.h"

#if AY_ENABLE_BEAUTY
#import "AyBeauty.h"
#endif

@interface AYGPUImageBeautyFilter ()

#if AY_ENABLE_BEAUTY
@property (nonatomic, strong) AyBeauty *beauty;
#endif

@property (nonatomic, strong) NSMutableDictionary *beautyDic;

@end

@implementation AYGPUImageBeautyFilter

- (id)initWithContext:(AYGPUImageContext *)context type:(AY_BEAUTY_TYPE)type{
    if (!(self = [super initWithContext:context])) {
        return nil;
    }
    
    _type = type;
    
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        _beauty = [[AyBeauty alloc] initWithType:type];
        [self.beauty initGLResource];
    });
#endif
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;{
    
    [self.context useAsCurrentContext];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];
    
#if AY_ENABLE_BEAUTY
    //------------->绘制图像<--------------//
    [self.beauty processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];

    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    //------------->绘制图像<--------------//
#endif

    [firstInputFramebuffer unlock];
}

- (void)setType:(AY_BEAUTY_TYPE)type {
    if (_type != type) {
        _type = type;
#if AY_ENABLE_BEAUTY
        runAYSynchronouslyOnContextQueue(self.context, ^{
            [self.context useAsCurrentContext];
            if (self.beauty) {
                [self.beauty releaseGLResource];
            }
            
            _beauty = [[AyBeauty alloc] initWithType:type];
            [self.beauty initGLResource];
        });
#endif
    }
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
#if AY_ENABLE_BEAUTY
    if (self.beauty.type != AY_BEAUTY_TYPE_2) { // 只有类型2能设置强度
        _intensity = 0;
        return;
    }
    [self.beauty setIntensity:intensity];
#endif
}

- (void)setSmooth:(CGFloat)smooth{
    _smooth = smooth;
#if AY_ENABLE_BEAUTY
    if (self.beauty.type == AY_BEAUTY_TYPE_2) { // 类型2没有磨皮
        _smooth = 0;
        _intensity = smooth;
        [self.beauty setIntensity:_intensity];
        return;
    }
    
    [self.beauty setSmooth:smooth];
#endif
}

- (void)setSaturation:(CGFloat)saturation{
    _saturation = saturation;
#if AY_ENABLE_BEAUTY
    if (self.beauty.type == AY_BEAUTY_TYPE_2) {// 类型2没有饱合度
        _saturation = 0;
        _intensity = saturation;
        [self.beauty setIntensity:_intensity];
        return;
    }
    
    [self.beauty setSaturation:saturation];
#endif
}

- (void)setWhiten:(CGFloat)whiten{
    _whiten = whiten;
#if AY_ENABLE_BEAUTY
    if (self.beauty.type == AY_BEAUTY_TYPE_2) {// 类型2没有美白
        _whiten = 0;
        _intensity = whiten;
        [self.beauty setIntensity:_intensity];
    }
    
    [self.beauty setWhiten:whiten];
#endif
}

- (void)dealloc{
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [_beauty releaseGLResource];
    });
#endif
}

@end
