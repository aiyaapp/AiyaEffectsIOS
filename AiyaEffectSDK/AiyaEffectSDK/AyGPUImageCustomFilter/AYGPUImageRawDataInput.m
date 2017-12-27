//
//  AYGPUImageRawDataInput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageRawDataInput.h"
#import "AYGPUImageFilter.h"
@interface AYGPUImageRawDataInput() {
    AYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
    
    GLuint inputDataTexture;
}

@end

@implementation AYGPUImageRawDataInput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
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
    
    return self;
}

- (void)processBGRADataWithCVPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    //    int bufferWidth = (int) CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int) CVPixelBufferGetHeight(pixelBuffer);
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [dataProgram use];
        
        outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(bytesPerRow / 4, bufferHeight) missCVPixelBuffer:YES];
        [outputFramebuffer activateFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        static const GLfloat noRotationTextureCoordinates[] = {
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
        };
        
        static const GLfloat verticalFlipTextureCoordinates[] = {
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f,  0.0f,
            1.0f,  0.0f,
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
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bytesPerRow / 4, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(pixelBuffer));
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        glUniform1i(dataInputTextureUniform, 1);
        
        glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        if (self.verticalFlip) {
            glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,verticalFlipTextureCoordinates);
        } else {
            glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,noRotationTextureCoordinates);
        }
        
        glEnableVertexAttribArray(dataPositionAttribute);
        glEnableVertexAttribArray(dataTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        for (id<AYGPUImageInput> currentTarget in targets)
        {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:CGSizeMake(bytesPerRow / 4, bufferHeight) atIndex:textureIndexOfTarget];
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
            [currentTarget newFrameReadyAtTime:kCMTimeInvalid atIndex:textureIndexOfTarget];
        }
        
        [outputFramebuffer unlock];
        
    });
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
