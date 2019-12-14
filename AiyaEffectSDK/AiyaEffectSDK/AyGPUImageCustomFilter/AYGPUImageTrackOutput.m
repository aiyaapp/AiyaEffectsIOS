//
//  AYGPUImageTrackOutput.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/1.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageTrackOutput.h"

#import "AYGLProgram.h"
#import "AYGPUImageFramebuffer.h"

#if AY_ENABLE_TRACK
#import "AyFaceTrack.h"
#endif

@interface AYGPUImageTrackOutput () {
    AYGPUImageFramebuffer *firstInputFramebuffer;
    
    AYGLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    AYGPUImageFramebuffer *outputFramebuffer;
    
    void *_faceData;
}

@property (nonatomic, weak) AYGPUImageContext *context;
@property (nonatomic, assign) CGSize outputSize;

#if AY_ENABLE_TRACK
@property (nonatomic, strong) AyFaceTrack *track;
#endif

@end

@implementation AYGPUImageTrackOutput

- (instancetype)initWithContext:(AYGPUImageContext *)context{
    if (!(self = [super init])) {
        return nil;
    }
    
    _context = context;
    
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
        
#if AY_ENABLE_TRACK
        _track = [[AyFaceTrack alloc] init];
#endif
    });
    
    return self;
}

- (void **)faceData {
    return &_faceData;
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    [dataProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(self.outputSize.width, self.outputSize.height) missCVPixelBuffer:NO];
    
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
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(dataInputTextureUniform, 4);
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0,noRotationTextureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
    
    [firstInputFramebuffer unlock];
    
#if AY_ENABLE_TRACK
    //获取人脸数据
    _faceData = NULL;

    GLubyte *trackBuffer = malloc(self.outputSize.width * self.outputSize.height * 4);
    
    // 拷贝图像数据到Buffer
    [outputFramebuffer lockForReading];
    GLubyte *outputBuffer = CVPixelBufferGetBaseAddress(outputFramebuffer.pixelBuffer);
    memcpy(trackBuffer, outputBuffer, self.outputSize.width * self.outputSize.height * 4);
    [outputFramebuffer unlockAfterReading];

    // 进行人脸识别
    [self.track trackWithPixelBuffer:trackBuffer bufferWidth:self.outputSize.width bufferHeight:self.outputSize.height trackData:self.faceData];

    free(trackBuffer);
#endif
    
    [outputFramebuffer unlock];
    outputFramebuffer = nil;
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)setInputSize:(CGSize)newSize {
    CGSize outputSize;
    outputSize.width = 176;
    outputSize.height = newSize.height * outputSize.width / newSize.width ;
    
    self.outputSize = outputSize;
}

- (void)setInputFramebuffer:(AYGPUImageFramebuffer *)newInputFramebuffer {
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)newFrameReady {
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self renderAtInternalSize];
    });
}

@end
