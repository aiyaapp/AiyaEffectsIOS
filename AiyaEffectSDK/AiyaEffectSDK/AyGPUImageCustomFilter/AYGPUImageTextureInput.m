//
//  AYGPUImageTextureInput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageTextureInput.h"
#import "AYGPUImageFilter.h"

@interface AYGPUImageTextureInput (){
    AYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
}

@end

@implementation AYGPUImageTextureInput

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


- (void)processBGRADataWithTexture:(GLint)texture width:(int)width height:(int)height{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [dataProgram use];
        
        outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
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
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texture);
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
            
            [currentTarget setInputSize:CGSizeMake(width, height) atIndex:textureIndexOfTarget];
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:textureIndexOfTarget];
            [currentTarget newFrameReadyAtTime:kCMTimeInvalid atIndex:textureIndexOfTarget];
        }
        
        [outputFramebuffer unlock];
    });
    
}

@end
