//
//  AySlimFace.m
//  AyBeauty
//
//  Created by 汪洋 on 2017/12/1.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AySlimFace.h"
#include "AiyaFaceProcessEffectInterface.h"

@interface AySlimFace () {
    AYSDK::AiyaFaceProcessEffect *slimFaceRender;
    
    BOOL initGL;
    
    BOOL updateIntensity;
    BOOL updateFaceData;

}
@end

@implementation AySlimFace

- (void)initGLResource{
    slimFaceRender = AYSDK::AiyaFaceProcessEffect::Create(0x2002);
}

- (void)releaseGLResource{
    if (slimFaceRender) {
        slimFaceRender->deinitGLResource();
        AYSDK::AiyaFaceProcessEffect::Destroy(slimFaceRender);
    }
}

- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height{
    if (!initGL) {
        slimFaceRender->initGLResource();
        
        initGL = YES;
    }
    
    if (updateIntensity) {
        slimFaceRender->set("Degree", self.intensity);
        
        updateIntensity = NO;
    }
    
    if (updateFaceData) {
        slimFaceRender->set("FaceData", 1, self.faceData);
        
        updateFaceData = NO;
    } else {
        slimFaceRender->set("FaceData", 0, NULL);
    }
    
    slimFaceRender->draw(texture, 0, 0, width, height);
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
