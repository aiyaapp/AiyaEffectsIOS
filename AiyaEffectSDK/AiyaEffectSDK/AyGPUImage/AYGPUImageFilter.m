//
//  AYGPUImageFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

// Hardcode the vertex shader for standard filters, but this can be overridden
NSString *const kAYGPUImageVertexShaderString = SHADER_STRING
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


NSString *const kAYGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

@implementation AYGPUImageFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(AYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithContext:context]))
    {
        return nil;
    }
    
    uniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];
    inputRotation = kAYGPUImageNoRotation;
    backgroundColorRed = 0.0;
    backgroundColorGreen = 0.0;
    backgroundColorBlue = 0.0;
    backgroundColorAlpha = 0.0;
    
    self.context = context;
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        filterProgram = [self.context programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
        if (!filterProgram.initialized)
        {
            if (![filterProgram link])
            {
                NSString *progLog = [filterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [filterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [filterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        filterPositionAttribute = [filterProgram attributeIndex:@"position"];
        filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
        filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        
        [filterProgram use];
        
        glEnableVertexAttribArray(filterPositionAttribute);
        glEnableVertexAttribArray(filterTextureCoordinateAttribute);
    });
    
    return self;
}

- (id)initWithContext:(AYGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [self initWithContext:context vertexShaderFromString:kAYGPUImageVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (id)initWithContext:(AYGPUImageContext *)context;
{
    if (!(self = [self initWithContext:context fragmentShaderFromString:kAYGPUImagePassthroughFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (void)dealloc
{
    
}

#pragma mark -
#pragma mark Managing the display FBOs

- (CGSize)sizeOfFBO;
{
    return inputTextureSize;
}

#pragma mark -
#pragma mark Rendering

+ (const GLfloat *)textureCoordinatesForRotation:(AYGPUImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    switch(rotationMode)
    {
        case kAYGPUImageNoRotation: return noRotationTextureCoordinates;
        case kAYGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kAYGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kAYGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kAYGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kAYGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kAYGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kAYGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    [self.context useAsCurrentContext];
    [filterProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:NO];
    [outputFramebuffer activateFramebuffer];
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
{
    if (self.frameProcessingCompletionBlock != NULL)
    {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    // Get all targets the framebuffer so they can grab a lock on it
    for (id<AYGPUImageInput> currentTarget in targets)
    {
        
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        
        [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
        [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
    }
    
    // Release our hold so it can return to the cache immediately upon processing
    [[self framebufferForOutput] unlock];
    
    [self removeOutputFramebuffer];
    
    // Trigger processing last, so that our unlock comes first in serial execution, avoiding the need for a callback
    for (id<AYGPUImageInput> currentTarget in targets)
    {
        
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
    }
}

- (CGSize)outputFrameSize;
{
    return inputTextureSize;
}

#pragma mark -
#pragma mark Input parameters

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
{
    backgroundColorRed = redComponent;
    backgroundColorGreen = greenComponent;
    backgroundColorBlue = blueComponent;
    backgroundColorAlpha = alphaComponent;
}

- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setInteger:newInteger forUniform:uniformIndex program:filterProgram];
}

- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setFloat:newFloat forUniform:uniformIndex program:filterProgram];
}

- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setSize:newSize forUniform:uniformIndex program:filterProgram];
}

- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setPoint:newPoint forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec3:(AYGPUVector3)newVec3 forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec3:newVec3 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatVec4:(AYGPUVector4)newVec4 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    [self setVec4:newVec4 forUniform:uniformIndex program:filterProgram];
}

- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName
{
    GLint uniformIndex = [filterProgram uniformIndex:uniformName];
    
    [self setFloatArray:array length:count forUniform:uniformIndex program:filterProgram];
}

- (void)setMatrix3f:(AYGPUMatrix3x3)matrix forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix3fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setMatrix4f:(AYGPUMatrix4x4)matrix forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix4fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1f(uniform, floatValue);
        }];
    });
}

- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat positionArray[2];
            positionArray[0] = pointValue.x;
            positionArray[1] = pointValue.y;
            
            glUniform2fv(uniform, 1, positionArray);
        }];
    });
}

- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat sizeArray[2];
            sizeArray[0] = sizeValue.width;
            sizeArray[1] = sizeValue.height;
            
            glUniform2fv(uniform, 1, sizeArray);
        }];
    });
}

- (void)setVec3:(AYGPUVector3)vectorValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform3fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setVec4:(AYGPUVector4)vectorValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform4fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    // Make a copy of the data, so it doesn't get overwritten before async call executes
    NSData* arrayData = [NSData dataWithBytes:arrayValue length:arrayLength * sizeof(arrayValue[0])];
    
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1fv(uniform, arrayLength, [arrayData bytes]);
        }];
    });
}

- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(AYGLProgram *)shaderProgram;
{
    runAYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [shaderProgram use];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1i(uniform, intValue);
        }];
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(AYGLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
{
    [uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    uniformStateBlock();
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_block_t currentBlock = obj;
        currentBlock();
    }];
}

#pragma mark -
#pragma mark AYGPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];
    
    [self informTargetsAboutNewFrameAtTime:frameTime];
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

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = sizeToRotate;
    
    if (AYGPUImageRotationSwapsWidthAndHeight(inputRotation))
    {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
    
    if (CGSizeEqualToSize(rotatedSize, CGSizeZero))
    {
        inputTextureSize = rotatedSize;
    }
    else if (!CGSizeEqualToSize(inputTextureSize, rotatedSize))
    {
        inputTextureSize = rotatedSize;
    }
}

- (void)setInputRotation:(AYGPUImageRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
{
    inputRotation = newInputRotation;
}

- (void)endProcessing
{
    if (!isEndProcessing)
    {
        isEndProcessing = YES;
        
        for (id<AYGPUImageInput> currentTarget in targets)
        {
            [currentTarget endProcessing];
        }
    }
}

@end
