//
//  AYYEGPUImageLookupFilter.m
//  AiyaVideoEffectSDK
//
//  Created by 汪洋 on 2017/11/21.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYYEGPUImageLookupFilter.h"

NSString *const kAYGPUImageLookupVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kAYGPUImageLookupFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform lowp float intensity;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 63.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
 }
 );

@interface AYYEGPUImageLookupFilter(){
    GLint filterInputTextureUniform2;
    GLint intensityUniform;

    GLuint styleTexture;
    BOOL updateStyleTexture;
}

@end

@implementation AYYEGPUImageLookupFilter

- (id)initWithContext:(AYYEGPUImageContext *)context{
    if (!(self = [super initWithContext:context vertexShaderFromString:kAYGPUImageLookupVertexShaderString fragmentShaderFromString:kAYGPUImageLookupFragmentShaderString])) {
        return nil;
    }
    
    runAYYESynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        filterInputTextureUniform2 = [filterProgram uniformIndex:@"inputImageTexture2"];
        
        intensityUniform = [filterProgram uniformIndex:@"intensity"];

        // 创建StyleTexture
        glGenTextures(1, &styleTexture);
        glBindTexture(GL_TEXTURE_2D, styleTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    });
    
    self.intensity = 1.0f;
    
    return self;
}

- (void)setStyle:(UIImage *)style{
    _style = style;
    
    updateStyleTexture = YES;
}

- (void)setIntensity:(CGFloat)intensity{
    _intensity = intensity;
    
    [self setFloat:_intensity forUniform:intensityUniform program:filterProgram];
}

- (void)dealloc{
    runAYYESynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (styleTexture) {
            glDeleteTextures(1, &styleTexture);
            styleTexture = 0;
        }
    });
}

@end
