//
//  AyShortVideoEffect.m
//  AyShortVideoEffect
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AyShortVideoEffect.h"
#include "AiyaShortVideoEffectInterface.h"

@interface AyShortVideoEffect () {
    AYSDK::AiyaShortVideoEffect *render;
    
    NSInteger _type;
    
    BOOL initGL;
    
    BOOL initFourScreen;
    BOOL initThreeScreen;
    
    BOOL needReset;
}

@end

@implementation AyShortVideoEffect

- (instancetype)initWithType:(NSInteger)type{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (void)initGLResource {
    render = AYSDK::AiyaShortVideoEffect::Create((int)_type);
    
    if(13 == _type){//AIYA_VIDEO_EFFECT_FOUR_SCREEN
        [self setFloatValue:-1 forKey:@"SubWindow"];
        [self setFloatValue:1 forKey:@"DrawGray"];
        
        initFourScreen = YES;
        
    }else if(14 == _type){//AIYA_VIDEO_EFFECT_THREE_SCREEN
        [self setFloatValue:-1 forKey:@"SubWindow"];
        [self setFloatValue:1 forKey:@"DrawGray"];
        
        initThreeScreen = YES;
        
    }
}

- (void)releaseGLResource {
    if (render) {
        render->deinitGLResource();
        AYSDK::AiyaShortVideoEffect::Destroy(render);
    }
}

- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height{
    if (!initGL) {
        render->initGLResource();
        
        initGL = YES;
    }
    
    if (needReset) {
        render->restart();
        
        if(13 == _type){//AIYA_VIDEO_EFFECT_FOUR_SCREEN
            [self setFloatValue:-1 forKey:@"SubWindow"];
            [self setFloatValue:1 forKey:@"DrawGray"];
            
            initFourScreen = YES;
            
        }else if(14 == _type){//AIYA_VIDEO_EFFECT_THREE_SCREEN
            [self setFloatValue:-1 forKey:@"SubWindow"];
            [self setFloatValue:1 forKey:@"DrawGray"];
            
            initThreeScreen = YES;
        }
        
        needReset = NO;
    }
    
    render->draw(texture, 0, 0, width, height);
    
    if (initFourScreen) {
        [self setFloatValue:0 forKey:@"SubWindow"];
        [self setFloatValue:0 forKey:@"DrawGray"];
        
        initFourScreen = NO;
    }
    
    if (initThreeScreen) {
        [self setFloatValue:0 forKey:@"SubWindow"];
        [self setFloatValue:0 forKey:@"DrawGray"];
        
        initThreeScreen = NO;
    }
}

- (void)reset{
    needReset = YES;
}

- (void)setFloatValue:(CGFloat)value forKey:(NSString *)key{
    render->set(key.UTF8String, value);
}

@end
