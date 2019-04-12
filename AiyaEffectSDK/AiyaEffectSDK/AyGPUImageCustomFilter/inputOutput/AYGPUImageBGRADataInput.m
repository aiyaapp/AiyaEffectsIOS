//
//  AYGPUImageBGRADataInput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageBGRADataInput.h"
#import "AYGPUImageFilter.h"
@interface AYGPUImageBGRADataInput() {
    AYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
    
    GLuint inputDataTexture;
}

@end

@implementation AYGPUImageBGRADataInput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    runAYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        
        dataProgram = [context programForVertexShaderString:kAYGPUImageVertexShaderString fragmentShaderString:kAYGPUImagePassthroughFragmentShaderString];
        
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
        dataInputTextureUniform = [dataProgram uniformIndex:@"inputImageTexture"];
    });
    return self;
}

- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [dataProgram use];
        
        if ([AYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
            outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(height, width) missCVPixelBuffer:YES];
        } else {
            outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) missCVPixelBuffer:YES];
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
        
        if (!inputDataTexture) {
            glGenTextures(1, &inputDataTexture);
            glBindTexture(GL_TEXTURE_2D, inputDataTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, inputDataTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, bgraData);
        
        glUniform1i(dataInputTextureUniform, 1);
        
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

- (void)processWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    int width = (int) CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
    int height = (int) CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* bgraData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    [self processWithBGRAData:bgraData width:width height:height];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)dealloc
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (inputDataTexture){
            glDeleteTextures(1, &inputDataTexture);
            inputDataTexture = 0;
        }
    });
}

@end
