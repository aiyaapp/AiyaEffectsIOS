//
//  AYGPUImageSlimFaceFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/30.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageSlimFaceFilter.h"
#if AY_ENABLE_BEAUTY
#import "AySlimFace.h"
#endif

@interface AYGPUImageSlimFaceFilter ()
#if AY_ENABLE_BEAUTY
@property (nonatomic, strong) AySlimFace *slimFace;
#endif
@end

@implementation AYGPUImageSlimFaceFilter

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString{
    if (!(self = [super initWithContext:context vertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString])) {
        return nil;
    }
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        _slimFace = [[AySlimFace alloc] init];
        [self.slimFace initGLResource];
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
    if (_faceData && *_faceData) {
        [self.slimFace setFaceData:*_faceData];
    }

    [self.slimFace processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    //------------->绘制图像<--------------//
#endif
    [firstInputFramebuffer unlock];
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
#if AY_ENABLE_BEAUTY
    [self.slimFace setIntensity:intensity];
#endif
}

- (void)dealloc{
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self.slimFace releaseGLResource];
    });
#endif
}

@end
