//
//  AYGPUImageConstants.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#ifndef AYGPUImageConstants_h
#define AYGPUImageConstants_h

#import <OpenGLES/ES2/gl.h>
#import <Foundation/Foundation.h>

typedef struct AYGPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} AYGPUTextureOptions;

typedef struct AYGPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
} AYGPUVector4;

typedef struct AYGPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
} AYGPUVector3;

typedef struct AYGPUMatrix4x4 {
    AYGPUVector4 one;
    AYGPUVector4 two;
    AYGPUVector4 three;
    AYGPUVector4 four;
} AYGPUMatrix4x4;

typedef struct AYGPUMatrix3x3 {
    AYGPUVector3 one;
    AYGPUVector3 two;
    AYGPUVector3 three;
} AYGPUMatrix3x3;

typedef NS_ENUM(NSUInteger, AYGPUImageRotationMode) {
    kAYGPUImageNoRotation,
    kAYGPUImageRotateLeft,
    kAYGPUImageRotateRight,
    kAYGPUImageFlipVertical,
    kAYGPUImageFlipHorizonal,
    kAYGPUImageRotateRightFlipVertical,
    kAYGPUImageRotateRightFlipHorizontal,
    kAYGPUImageRotate180
};

#endif /* AYGPUImageConstants_h */
