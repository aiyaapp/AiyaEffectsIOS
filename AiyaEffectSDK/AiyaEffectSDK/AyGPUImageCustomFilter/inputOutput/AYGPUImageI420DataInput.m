//
//  AYGPUImageI420DataInput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/5/27.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageI420DataInput.h"
#import "AYGPUImageFilter.h"
#import "AYGPUImageNV12DataInput.h"

// Fragment Shader String
NSString *const kAYRGBConversion2FragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D yTexture;
 uniform sampler2D uTexture;
 uniform sampler2D vTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     yuv.x = texture2D(yTexture, textureCoordinate).r;
     yuv.y = texture2D(uTexture, textureCoordinate).r - 0.5;
     yuv.z = texture2D(vTexture, textureCoordinate).r - 0.5;
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb, 1);
 }
 );

@interface AYGPUImageI420DataInput() {
    AYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint datayTextureUniform;
    GLint datauTextureUniform;
    GLint datavTextureUniform;

    GLint colorConversionUniform;
    
    GLuint inputyTexture;
    GLuint inputuTexture;
    GLuint inputvTexture;
}

@end

@implementation AYGPUImageI420DataInput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    [context useAsCurrentContext];
    
    runAYSynchronouslyOnContextQueue(context, ^{
        dataProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAYRGBConversion2FragmentShaderString];
        
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
        datayTextureUniform = [dataProgram uniformIndex:@"yTexture"];
        datauTextureUniform = [dataProgram uniformIndex:@"uTexture"];
        datavTextureUniform = [dataProgram uniformIndex:@"vTexture"];
        colorConversionUniform = [dataProgram uniformIndex:@"colorConversionMatrix"];
    });
        
    return self;
}

- (void)processWithYData:(void *)yData uData:(void *)uData vData:(void *)vData width:(int)width height:(int)height{
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
        
        if (!inputyTexture) {
            glGenTextures(1, &inputyTexture);
            glBindTexture(GL_TEXTURE_2D, inputyTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        if (!inputuTexture) {
            glGenTextures(1, &inputuTexture);
            glBindTexture(GL_TEXTURE_2D, inputuTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        if (!inputvTexture) {
            glGenTextures(1, &inputvTexture);
            glBindTexture(GL_TEXTURE_2D, inputvTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputyTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, yData);
        glUniform1i(datayTextureUniform, 1);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, inputuTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width / 2, height / 2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, uData);
        glUniform1i(datauTextureUniform, 2);
        
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, inputvTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width / 2, height / 2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, vData);
        glUniform1i(datavTextureUniform, 3);
        
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

- (void)dealloc
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (inputyTexture){
            glDeleteTextures(1, &inputyTexture);
            inputyTexture = 0;
        }
        
        if (inputuTexture){
            glDeleteTextures(1, &inputuTexture);
            inputuTexture = 0;
        }
        
        if (inputvTexture){
            glDeleteTextures(1, &inputvTexture);
            inputvTexture = 0;
        }
    });
}


@end
