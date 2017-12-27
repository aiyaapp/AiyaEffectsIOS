//
//  AyBeauty.m
//  AyBeauty
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AyBeauty.h"
#include "AiyaBeautyEffectInterface.h"

@interface AyBeauty () {
    AYSDK::AiyaBeautyEffect *render;
    
    NSInteger _type;
    
    BOOL initGL;
    
    BOOL updateIntensity;
    BOOL updateSmooth;
    BOOL updateSaturation;
    BOOL updateWhiten;
}
@end

@implementation AyBeauty

- (instancetype)initWithType:(NSInteger)type{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (void)initGLResource{
    render = AYSDK::AiyaBeautyEffect::Create((int)_type);
}

- (void)releaseGLResource{
    if (render) {
        render->deinitGLResource();
        AYSDK::AiyaBeautyEffect::Destroy(render);
    }
}

- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height{
    if (!initGL) {
        render->initGLResource();
        
        initGL = YES;
    }

    if (updateIntensity) {
        render->set("Degree", self.intensity);
        
        updateIntensity = NO;
    }
    
    if (updateSmooth) {
        render->set("SmoothDegree", self.smooth);
        
        updateSmooth = NO;
    }
    
    if (updateSaturation) {
        render->set("SaturateDegree", self.saturation);
        
        updateSaturation = NO;
    }
    
    if (updateWhiten) {
        render->set("WhitenDegree", self.whiten);
        
        updateWhiten = NO;
    }
    
    render->draw(texture, 0, 0, width, height);
}

- (CGFloat)type{
    return _type;
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
    
    updateIntensity = YES;
}

- (void)setSmooth:(CGFloat)smooth{
    _smooth = smooth;
    
    updateSmooth = YES;
}

- (void)setSaturation:(CGFloat)saturation{
    _saturation = saturation;
    
    updateSaturation = YES;
}

- (void)setWhiten:(CGFloat)whiten{
    _whiten = whiten;
    
    updateWhiten = YES;
}

@end
