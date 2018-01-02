//
//  CameraDataProcess.h
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraDataProcessDelegate <NSObject>

/**
 回调相机BGRA纹理数据

 @param texture 纹理
 @return 返回的纹理
 */
- (GLuint)cameraDataProcessWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height;

@end

/**
 输入CMSampleBuffer 转换成纹理处理, 处理完成后输出到CMSampleBuffer;
 */
@interface CameraDataProcess : NSObject

@property (nonatomic, weak) id <CameraDataProcessDelegate> delegate;

/**
 镜像
 */
@property (nonatomic, assign) BOOL mirror;

- (CMSampleBufferRef)process:(CMSampleBufferRef)sampleBuffer;

@end
