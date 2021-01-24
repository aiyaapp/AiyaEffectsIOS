//
//  AYPreview.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2019/12/11.
//  Copyright © 2019 深圳哎吖科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <AVKit/AVKit.h>

typedef NS_ENUM(NSUInteger, AYPreivewContentMode) {
    AYPreivewContentModeScaleToFill,
    AYPreivewContentModeScaleAspectFit,
    AYPreivewContentModeScaleAspectFill
};

typedef NS_ENUM(NSUInteger, AYPreviewRotationMode) {
    kAYPreviewNoRotation,
    kAYPreviewRotateLeft,
    kAYPreviewRotateRight,
    kAYPreviewFlipVertical,
    kAYPreviewFlipHorizonal,
    kAYPreviewRotateRightFlipVertical,
    kAYPreviewRotateRightFlipHorizontal,
    kAYPreviewRotate180
};

@interface AYPixelBufferPreview : UIView

/**
 内容填充方式
 */
@property (nonatomic, assign) AYPreivewContentMode previewContentMode;

/**
 内容方向
 */
@property (nonatomic, assign) AYPreviewRotationMode previewRotationMode;

/**
 渲染BGRA数据
 */
- (void)render:(CVPixelBufferRef)CVPixelBuffer;

/**
 当不使用GL时及时释放, 在使用时会自动重新创建
 */
- (void)releaseGLResources;

@end

@interface AYPixelBufferPreview (OpenGLHelper)

// 创建 program
+ (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString;

// 通过旋转方向创建纹理坐标
+ (const GLfloat *)textureCoordinatesForRotation:(AYPreviewRotationMode)rotationMode;

+ (BOOL)needExchangeWidthAndHeightWithPreviewRotation:(AYPreviewRotationMode)rotationMode;

@end
