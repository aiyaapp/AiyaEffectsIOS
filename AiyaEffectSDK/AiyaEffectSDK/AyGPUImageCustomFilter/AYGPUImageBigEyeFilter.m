//
//  AYGPUImageBigEyeFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/30.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageBigEyeFilter.h"

#if AY_ENABLE_BEAUTY
#import "AyBigEye.h"
#endif

@interface AYGPUImageBigEyeFilter ()
#if AY_ENABLE_BEAUTY
@property (nonatomic, strong) AyBigEye *bigEye;
#endif
@end

@implementation AYGPUImageBigEyeFilter

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString{
    if (!(self = [super initWithContext:context vertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString])) {
        return nil;
    }
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        _bigEye = [[AyBigEye alloc] init];
        [self.bigEye initGLResource];
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
        [self.bigEye setFaceData:*_faceData];
    }
    
    [self.bigEye processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    //------------->绘制图像<--------------//
#endif
    [firstInputFramebuffer unlock];
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
#if AY_ENABLE_BEAUTY
    [self.bigEye setIntensity:intensity];
#endif
}

- (void)dealloc{
#if AY_ENABLE_BEAUTY
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self.bigEye releaseGLResource];
    });
#endif
}

@end
