//
//  AYGPUImageNV12DataInput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/26.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageNV12DataInput.h"
#import "AYGPUImageFilter.h"

// Fragment Shader String
NSString *const kAYRGBConversionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D luminanceTexture;
 uniform sampler2D chrominanceTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb, 1);
 }
);

// BT.601 full range.
GLfloat kAYColorConversion601FullRangeDefault[] = {
    1.000,        1.000,       1.000,
    0.000,       -0.343,       1.765,
    1.400,       -0.711,       0.000
};

@interface AYGPUImageNV12DataInput() {
    AYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataLuminanceTextureUniform;
    GLint dataChrominanceTextureUniform;
    
    GLint colorConversionUniform;
    
    GLuint inputLuminanceTexture;
    GLuint inputChrominanceTexture;
    
}

@end

@implementation AYGPUImageNV12DataInput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    runAYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        
        dataProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAYRGBConversionFragmentShaderString];
        
        if (!dataProgram.initialized)
        {
            if (![dataProgram link])
            {
                NSString *progLog = [dataProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [dataProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [dataProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                dataProgram = nil;
            }
        }
        
        dataPositionAttribute = [dataProgram attributeIndex:@"position"];
        dataTextureCoordinateAttribute = [dataProgram attributeIndex:@"inputTextureCoordinate"];
        dataLuminanceTextureUniform = [dataProgram uniformIndex:@"luminanceTexture"];
        dataChrominanceTextureUniform = [dataProgram uniformIndex:@"chrominanceTexture"];
        colorConversionUniform = [dataProgram uniformIndex:@"colorConversionMatrix"];
    });
    return self;
}

- (void)processWithYData:(void *)yData uvData:(void *)uvData width:(int)width height:(int)height{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [dataProgram use];
        
        if ([AYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
            outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(height, width) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        } else {
            outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        }
        [outputFramebuffer activateFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        if (!inputLuminanceTexture) {
            glGenTextures(1, &inputLuminanceTexture);
            glBindTexture(GL_TEXTURE_2D, inputLuminanceTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        if (!inputChrominanceTexture) {
            glGenTextures(1, &inputChrominanceTexture);
            glBindTexture(GL_TEXTURE_2D, inputChrominanceTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputLuminanceTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, width, height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yData);
        glUniform1i(dataLuminanceTextureUniform, 1);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputChrominanceTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE_ALPHA, width / 2, height / 2, 0, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, uvData);
        glUniform1i(dataChrominanceTextureUniform, 1);
        
        glUniformMatrix3fv(colorConversionUniform, 1, GL_FALSE, kAYColorConversion601FullRangeDefault);
        
        glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [AYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
        
        glEnableVertexAttribArray(dataPositionAttribute);
        glEnableVertexAttribArray(dataTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        for (id<AYGPUImageInput> currentTarget in targets)
        {
            if ([AYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
                [currentTarget setInputSize:CGSizeMake(height, width)];
            } else {
                [currentTarget setInputSize:CGSizeMake(width, height)];
            }
            [currentTarget setInputFramebuffer:outputFramebuffer];
            [currentTarget newFrameReady];
        }
        
        [outputFramebuffer unlock];
    });
}

- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    int width = (int) CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    int height = (int) CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *yData = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    void *uvData = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    [self processWithYData:yData uvData:uvData width:width height:height];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)dealloc
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (inputLuminanceTexture){
            glDeleteTextures(1, &inputLuminanceTexture);
            inputLuminanceTexture = 0;
        }
        
        if (inputChrominanceTexture){
            glDeleteTextures(1, &inputChrominanceTexture);
            inputChrominanceTexture = 0;
        }
    });
}


@end
