//
//  VideoEffectHandler.h
//  LLSimpleCameraExample
//
//  Created by 汪洋 on 2017/9/30.
//  Copyright © 2017年 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import <CoreMedia/CoreMedia.h>

@interface VideoEffectHandlerView : UIView

/**
 设置特效类型

 @param effectType 特效类型
 */
- (void)setEffectType:(NSInteger)effectType;


/**
 使用指定的特效类型处理sampleBuffer封装的数据

 @param sampleBuffer 一帧视频数据,格式为yuv420f
 @param transformMatrix 视频数据的旋转方向
 @param outputSize 视频的大小
 @return 返回一帧视频数据
 */
- (CMSampleBufferRef)process:(CMSampleBufferRef)sampleBuffer transformMatrix:(GLfloat *)transformMatrix outputSize:(CGSize)outputSize;

@end
