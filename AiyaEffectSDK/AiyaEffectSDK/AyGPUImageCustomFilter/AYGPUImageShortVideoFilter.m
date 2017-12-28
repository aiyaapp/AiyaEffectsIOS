//
//  AYGPUImageShortVideoFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/2.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageShortVideoFilter.h"
#if AY_ENABLE_SHORT_VIDEO
#import "AyShortVideoEffect.h"
#endif

@interface AYGPUImageShortVideoFilter ()

#if AY_ENABLE_SHORT_VIDEO
@property (nonatomic, strong) NSMutableDictionary *shortVideoDic;
@property (nonatomic, strong) AyShortVideoEffect *shortVideo;
#endif

@end

@implementation AYGPUImageShortVideoFilter

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString{
    if (!(self = [super initWithContext:context vertexShaderFromString:vertexShaderString fragmentShaderFromString:fragmentShaderString])) {
        return nil;
    }
    
#if AY_ENABLE_SHORT_VIDEO
    _shortVideoDic = [NSMutableDictionary dictionary];
#endif
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates{
    
    [self.context useAsCurrentContext];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];
    
#if AY_ENABLE_SHORT_VIDEO
    //------------->绘制图像<--------------//
    _shortVideo = [self.shortVideoDic objectForKey:@(self.type)];
    
    if (!self.shortVideo) {
        self.shortVideo = [[AyShortVideoEffect alloc] initWithType:self.type];
        [self.shortVideo initGLResource];
        
        [self.shortVideoDic setObject:self.shortVideo forKey:@(self.type)];
    }
    
    [self.shortVideo processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];
    
    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    //------------->绘制图像<--------------//
#endif
    
    [firstInputFramebuffer unlock];
}

- (void)setFloatValue:(CGFloat)value forKey:(NSString *)key{
#if AY_ENABLE_SHORT_VIDEO
    [self.shortVideo setFloatValue:value forKey:key];
#endif
}

- (void)reset{
#if AY_ENABLE_SHORT_VIDEO
    [self.shortVideo reset];
#endif
}

- (void)dealloc{
#if AY_ENABLE_SHORT_VIDEO
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        for (AyShortVideoEffect *shortVideo in self.shortVideoDic.allValues) {
            [shortVideo releaseGLResource];
        }
    });
#endif
}
@end
