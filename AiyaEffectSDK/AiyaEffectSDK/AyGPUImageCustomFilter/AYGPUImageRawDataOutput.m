//
//  AYGPUImageRawDataOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageRawDataOutput.h"

#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"

@interface AYGPUImageRawDataOutput (){
    AYGPUImageFramebuffer *firstInputFramebuffer;
    
    AYGLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    AYGPUImageFramebuffer *outputFramebuffer;
    
    int outputWidth;
    int outputHeight;
}

@property (nonatomic, weak) AYGPUImageContext *context;
@property (nonatomic, assign) CGSize inputSize;

@property (nonatomic, assign) CVPixelBufferRef pixelBuffer;

@end

@implementation AYGPUImageRawDataOutput

- (instancetype)initWithContext:(AYGPUImageContext *)context
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _context = context;
    
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

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    [dataProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(outputWidth, outputHeight) missCVPixelBuffer:NO];
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
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(dataInputTextureUniform, 4);
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    if (self.verticalFlip) {
        glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,verticalFlipTextureCoordinates);
    } else {
        glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,noRotationTextureCoordinates);
    }
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
    
    [firstInputFramebuffer unlock];
    
    //导出数据
    CVPixelBufferLockBaseAddress(self.pixelBuffer, 0);
    
    uint8_t *targetBuffer = CVPixelBufferGetBaseAddress(self.pixelBuffer);
    
    GLubyte *outputBuffer = outputFramebuffer.byteBuffer;
    
    memcpy(targetBuffer, outputBuffer, outputWidth * outputHeight * 4);
    
    CVPixelBufferUnlockBaseAddress(self.pixelBuffer, 0);
    
    [outputFramebuffer unlock];
}

- (void)setOutputCVPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    self.pixelBuffer = pixelBuffer;
    
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
    outputWidth = bytesPerRow / 4;
    outputHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self renderAtInternalSize];
    });
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(AYGPUImageFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)setInputRotation:(AYGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex{
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
}

- (CGSize)maximumOutputSize;
{
    return CGSizeZero;
}

- (void)endProcessing;
{
    
}

@end
