//
//  AYGPUImageGaussianBlurFilter.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2018/3/16.
//  Copyright © 2018年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageGaussianBlurFilter.h"

@interface AYGPUImageGaussianBlurFilter () {
    GLint verticalPassTexelWidthOffsetUniform;
    GLint verticalPassTexelHeightOffsetUniform;
    
    AYGPUImageFramebuffer *secondOutputFramebuffer;
    
    AYGLProgram *gaussianBlurProgram;
    
    GLint gaussianBlurPositionAttribute, gaussianBlurTextureCoordinateAttribute;
    GLint gaussianBlurInputTextureUniform;
}
@end

@implementation AYGPUImageGaussianBlurFilter

+ (NSString *)vertexShaderForOptimizedBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma {
    
    // First, generate the normal Gaussian weights for a given sigma
    GLfloat *standardGaussianWeights = calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++){
        
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0){
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        } else {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
    
    // From these weights we calculate the offsets to read interpolated values from
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    GLfloat *optimizedGaussianOffsets = calloc(numberOfOptimizedOffsets, sizeof(GLfloat));
    
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++){
        GLfloat firstWeight = standardGaussianWeights[currentOptimizedOffset*2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentOptimizedOffset*2 + 2];
        
        GLfloat optimizedWeight = firstWeight + secondWeight;
        
        optimizedGaussianOffsets[currentOptimizedOffset] = (firstWeight * (currentOptimizedOffset*2 + 1) + secondWeight * (currentOptimizedOffset*2 + 2)) / optimizedWeight;
    }
    
    NSMutableString *shaderString = [[NSMutableString alloc] init];
    // Header
    [shaderString appendFormat:@"\
     attribute vec4 position;\n\
     attribute vec4 inputTextureCoordinate;\n\
     \n\
     uniform float texelWidthOffset;\n\
     uniform float texelHeightOffset;\n\
     \n\
     varying vec2 blurCoordinates[%lu];\n\
     \n\
     void main()\n\
     {\n\
     gl_Position = position;\n\
     \n\
     vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);\n", (unsigned long)(1 + (numberOfOptimizedOffsets * 2))];
    
    // Inner offset loop
    [shaderString appendString:@"blurCoordinates[0] = inputTextureCoordinate.xy;\n"];
    for (NSUInteger currentOptimizedOffset = 0; currentOptimizedOffset < numberOfOptimizedOffsets; currentOptimizedOffset++) {
        [shaderString appendFormat:@"\
         blurCoordinates[%lu] = inputTextureCoordinate.xy + singleStepOffset * %f;\n\
         blurCoordinates[%lu] = inputTextureCoordinate.xy - singleStepOffset * %f;\n", (unsigned long)((currentOptimizedOffset * 2) + 1), optimizedGaussianOffsets[currentOptimizedOffset], (unsigned long)((currentOptimizedOffset * 2) + 2), optimizedGaussianOffsets[currentOptimizedOffset]];
    }
    
    // Footer
    [shaderString appendString:@"}\n"];
    
    free(optimizedGaussianOffsets);
    free(standardGaussianWeights);
    return shaderString;
}

+ (NSString *)fragmentShaderForOptimizedBlurOfRadius:(NSUInteger)blurRadius sigma:(CGFloat)sigma {

    // First, generate the normal Gaussian weights for a given sigma
    GLfloat *standardGaussianWeights = calloc(blurRadius + 1, sizeof(GLfloat));
    GLfloat sumOfWeights = 0.0;
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = (1.0 / sqrt(2.0 * M_PI * pow(sigma, 2.0))) * exp(-pow(currentGaussianWeightIndex, 2.0) / (2.0 * pow(sigma, 2.0)));
        
        if (currentGaussianWeightIndex == 0) {
            sumOfWeights += standardGaussianWeights[currentGaussianWeightIndex];
        } else {
            sumOfWeights += 2.0 * standardGaussianWeights[currentGaussianWeightIndex];
        }
    }
    
    // Next, normalize these weights to prevent the clipping of the Gaussian curve at the end of the discrete samples from reducing luminance
    for (NSUInteger currentGaussianWeightIndex = 0; currentGaussianWeightIndex < blurRadius + 1; currentGaussianWeightIndex++) {
        standardGaussianWeights[currentGaussianWeightIndex] = standardGaussianWeights[currentGaussianWeightIndex] / sumOfWeights;
    }
    
    // From these weights we calculate the offsets to read interpolated values from
    NSUInteger numberOfOptimizedOffsets = MIN(blurRadius / 2 + (blurRadius % 2), 7);
    NSUInteger trueNumberOfOptimizedOffsets = blurRadius / 2 + (blurRadius % 2);
    
    NSMutableString *shaderString = [[NSMutableString alloc] init];
    
    // Header
    [shaderString appendFormat:@"\
     uniform sampler2D inputImageTexture;\n\
     uniform highp float texelWidthOffset;\n\
     uniform highp float texelHeightOffset;\n\
     \n\
     varying highp vec2 blurCoordinates[%lu];\n\
     \n\
     void main()\n\
     {\n\
     lowp vec4 sum = vec4(0.0);\n", (unsigned long)(1 + (numberOfOptimizedOffsets * 2)) ];
    
    // Inner texture loop
    [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0]) * %f;\n", standardGaussianWeights[0]];
    
    for (NSUInteger currentBlurCoordinateIndex = 0; currentBlurCoordinateIndex < numberOfOptimizedOffsets; currentBlurCoordinateIndex++) {
        GLfloat firstWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 1];
        GLfloat secondWeight = standardGaussianWeights[currentBlurCoordinateIndex * 2 + 2];
        GLfloat optimizedWeight = firstWeight + secondWeight;
        
        [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%lu]) * %f;\n", (unsigned long)((currentBlurCoordinateIndex * 2) + 1), optimizedWeight];
        [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[%lu]) * %f;\n", (unsigned long)((currentBlurCoordinateIndex * 2) + 2), optimizedWeight];
    }
    
    // If the number of required samples exceeds the amount we can pass in via varyings, we have to do dependent texture reads in the fragment shader
    if (trueNumberOfOptimizedOffsets > numberOfOptimizedOffsets) {
        [shaderString appendString:@"highp vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);\n"];
        
        for (NSUInteger currentOverlowTextureRead = numberOfOptimizedOffsets; currentOverlowTextureRead < trueNumberOfOptimizedOffsets; currentOverlowTextureRead++) {
            GLfloat firstWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 1];
            GLfloat secondWeight = standardGaussianWeights[currentOverlowTextureRead * 2 + 2];
            
            GLfloat optimizedWeight = firstWeight + secondWeight;
            GLfloat optimizedOffset = (firstWeight * (currentOverlowTextureRead * 2 + 1) + secondWeight * (currentOverlowTextureRead * 2 + 2)) / optimizedWeight;
            
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0] + singleStepOffset * %f) * %f;\n", optimizedOffset, optimizedWeight];
            [shaderString appendFormat:@"sum += texture2D(inputImageTexture, blurCoordinates[0] - singleStepOffset * %f) * %f;\n", optimizedOffset, optimizedWeight];
        }
    }
    
    // Footer
    [shaderString appendString:@"\
     gl_FragColor = sum;\n\
     }\n"];
    
    free(standardGaussianWeights);
    return shaderString;
}


// inputRadius for Core Image's CIGaussianBlur is really sigma in the Gaussian equation, so I'm using that for my blur radius, to be consistent
- (void)setBlurRadiusInPixels:(CGFloat)newValue;
{
    // 7.0 is the limit for blur size for hardcoded varying offsets
    if (round(newValue) != _blurRadiusInPixels) {
        _blurRadiusInPixels = round(newValue); // For now, only do integral sigmas
        
        if (_blurRadiusInPixels >= 1) {
            NSUInteger calculatedSampleRadius = 0;
                
            // Calculate the number of pixels to sample from by setting a bottom limit for the contribution of the outermost pixel
            CGFloat minimumWeightToFindEdgeOfSamplingArea = 1.0/256.0;
            calculatedSampleRadius = floor(sqrt(-2.0 * pow(_blurRadiusInPixels, 2.0) * log(minimumWeightToFindEdgeOfSamplingArea * sqrt(2.0 * M_PI * pow(_blurRadiusInPixels, 2.0))) ));
            calculatedSampleRadius += calculatedSampleRadius % 2; // There's nothing to gain from handling odd radius sizes, due to the optimizations I use
            
            //        NSLog(@"Blur radius: %f, calculated sample radius: %d", _blurRadiusInPixels, calculatedSampleRadius);
            //
            NSString *newGaussianBlurVertexShader = [[self class] vertexShaderForOptimizedBlurOfRadius:calculatedSampleRadius sigma:_blurRadiusInPixels];
            NSString *newGaussianBlurFragmentShader = [[self class] fragmentShaderForOptimizedBlurOfRadius:calculatedSampleRadius sigma:_blurRadiusInPixels];
            
            //        NSLog(@"Optimized vertex shader: \n%@", newGaussianBlurVertexShader);
            //        NSLog(@"Optimized fragment shader: \n%@", newGaussianBlurFragmentShader);
            
            [self switchToVertexShader:newGaussianBlurVertexShader fragmentShader:newGaussianBlurFragmentShader];
        }
    }
}


- (void)switchToVertexShader:(NSString *)vertexShaderString fragmentShader:(NSString *)fragmentShaderString;
{
    runAYSynchronouslyOnContextQueue(self.context,^{
        [self.context useAsCurrentContext];

        gaussianBlurProgram = [[AYGLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
        if (!gaussianBlurProgram.initialized)
        {
            if (![gaussianBlurProgram link])
            {
                NSString *progLog = [gaussianBlurProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [gaussianBlurProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [gaussianBlurProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                gaussianBlurProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
    
        gaussianBlurPositionAttribute = [gaussianBlurProgram attributeIndex:@"position"];
        gaussianBlurTextureCoordinateAttribute = [gaussianBlurProgram attributeIndex:@"inputTextureCoordinate"];
        gaussianBlurInputTextureUniform = [gaussianBlurProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
        verticalPassTexelWidthOffsetUniform = [gaussianBlurProgram uniformIndex:@"texelWidthOffset"];
        verticalPassTexelHeightOffsetUniform = [gaussianBlurProgram uniformIndex:@"texelHeightOffset"];
        
        [gaussianBlurProgram use];

        glEnableVertexAttribArray(gaussianBlurPositionAttribute);
        glEnableVertexAttribArray(gaussianBlurTextureCoordinateAttribute);
        
    });
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    if (_blurRadiusInPixels >= 1) {
        [gaussianBlurProgram use];
        
        secondOutputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        [secondOutputFramebuffer activateFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
        glUniform1i(gaussianBlurInputTextureUniform, 2);
        
        glUniform1f(verticalPassTexelWidthOffsetUniform, 1.0f / inputTextureSize.width);
        glUniform1f(verticalPassTexelHeightOffsetUniform, 0);
        
        glVertexAttribPointer(gaussianBlurPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glVertexAttribPointer(gaussianBlurTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        [outputFramebuffer activateFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, [secondOutputFramebuffer texture]);
        glUniform1i(gaussianBlurInputTextureUniform, 2);
        
        glUniform1f(verticalPassTexelWidthOffsetUniform, 0);
        glUniform1f(verticalPassTexelHeightOffsetUniform, 1.0f / inputTextureSize.height);
        
        glVertexAttribPointer(gaussianBlurPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
        glVertexAttribPointer(gaussianBlurTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        [firstInputFramebuffer unlock];
        [secondOutputFramebuffer unlock];
        
    } else {
        [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    }
}

@end
