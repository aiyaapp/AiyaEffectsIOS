//
//  AyBigEye.m
//  AyBeauty
//
//  Created by 汪洋 on 2017/12/1.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AyBigEye.h"
#include "AiyaFaceProcessEffectInterface.h"

@interface AyBigEye () {
    AYSDK::AiyaFaceProcessEffect *bigEyeRender;

    BOOL initGL;

    BOOL updateIntensity;
    BOOL updateFaceData;
}
@end

@implementation AyBigEye

- (void)initGLResource{
    bigEyeRender = AYSDK::AiyaFaceProcessEffect::Create(0x2001);
}

- (void)releaseGLResource{
    if (bigEyeRender) {
        bigEyeRender->deinitGLResource();
        AYSDK::AiyaFaceProcessEffect::Destroy(bigEyeRender);
    }
}

- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height{
    if (!initGL) {
        bigEyeRender->initGLResource();
        
        initGL = YES;
    }
    
    if (updateIntensity) {
        bigEyeRender->set("Degree", self.intensity);
        
        updateIntensity = NO;
    }
    
    if (updateFaceData) {
        bigEyeRender->set("FaceData", 1, self.faceData);
        
        updateFaceData = NO;
    } else {
        bigEyeRender->set("FaceData", 0, NULL);
    }
    
    bigEyeRender->draw(texture, 0, 0, width, height);
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
    
    updateIntensity = YES;
}

- (void)setFaceData:(void *)faceData{
    _faceData = faceData;
    
    updateFaceData = YES;
}
@end
