//
//  AYYEGPUImageConstants.h
//  AiyaVideoEffectSDK
//
//  Created by 汪洋 on 2017/11/7.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <Foundation/Foundation.h>

typedef struct AYYEGPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} AYYEGPUTextureOptions;

typedef struct AYYEGPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
} AYYEGPUVector4;

typedef struct AYYEGPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
} AYYEGPUVector3;

typedef struct AYYEGPUMatrix4x4 {
    AYYEGPUVector4 one;
    AYYEGPUVector4 two;
    AYYEGPUVector4 three;
    AYYEGPUVector4 four;
} AYYEGPUMatrix4x4;

typedef struct AYYEGPUMatrix3x3 {
    AYYEGPUVector3 one;
    AYYEGPUVector3 two;
    AYYEGPUVector3 three;
} AYYEGPUMatrix3x3;

typedef NS_ENUM(NSUInteger, AYYEGPUImageRotationMode) {
    kAYYEGPUImageNoRotation,
    kAYYEGPUImageRotateLeft,
    kAYYEGPUImageRotateRight,
    kAYYEGPUImageFlipVertical,
    kAYYEGPUImageFlipHorizonal,
    kAYYEGPUImageRotateRightFlipVertical,
    kAYYEGPUImageRotateRightFlipHorizontal,
    kAYYEGPUImageRotate180
};

