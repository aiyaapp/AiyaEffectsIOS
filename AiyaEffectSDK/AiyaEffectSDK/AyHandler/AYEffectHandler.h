//
//  AYEffectHandler.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "AYGPUImageConstants.h"

@protocol AYEffectHandlerDelegate <NSObject>

/**
 播放结束
 */
- (void)playEnd;

@end

@interface AYEffectHandler : NSObject

@property (nonatomic, weak) id<AYEffectHandlerDelegate> delegate;

/**
 设置特效,通过设置特效文件路径的方式,默认空值,空值表示取消渲染特效
 */
@property (nonatomic, strong) NSString *effectPath;

/**
 设置特效播放次数
 */
@property (nonatomic, assign) NSUInteger effectPlayCount;

/**
 设置风格滤镜
 */
@property (nonatomic, strong) UIImage *style;
@property (nonatomic, assign) CGFloat intensityOfStyle;

/**
 当前的美颜算法类型, 共有6种美颜算法. 当前使用的是AY_BEAUTY_TYPE_5
 */
@property (nonatomic, assign) NSInteger beautyAlgorithmType;

/**
 设置磨皮 默认0 最高为1
 */
@property (nonatomic, assign) CGFloat smooth;

/**
 设置饱合度 默认0 最高为1
 */
@property (nonatomic, assign) CGFloat saturation;

/**
 设置美白 默认0 最高为1
 */
@property (nonatomic, assign) CGFloat whiten;

/**
 设置大眼强度 默认0 最高为1
 */
@property (nonatomic, assign) CGFloat bigEye;

/**
 设置瘦脸强度 默认0 最高为1
 */
@property (nonatomic, assign) CGFloat slimFace;

/**
 设置特效旋转或者翻转, 共8个方向
 */
@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

/**
 初始化判断是否是处理纹理数据
 */
- (instancetype)initWithProcessTexture:(Boolean)isProcessTexture;

/**
 清空所有资源
 */
- (void)destroy;

/**
 暂停特效播放
 */
- (void)pauseEffect;

/**
 继续特效播放
 */
- (void)resumeEffect;

/**
 处理纹理数据

 @param texture 纹理数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height;

/**
 处理iOS封装的数据
 
 @param pixelBuffer BGRA格式数据
 @param formatType 只支持kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 和 kCVPixelFormatType_32BGRA
 */
- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer formatType:(OSType)formatType;

/**
 处理原始数据, 格式为NV12, 对应iOS相机输出数据格式420YpCbCr8BiPlanarFullRange
 
 ----------plane0
 Y1 Y2 Y3 Y4
 Y5 Y6 Y7 Y8
 ----------plane1
 U1 V1 U2 V2
 
 @param yBuffer 灰度数据
 @param uvBuffer 色度数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithYBuffer:(void *)yBuffer uvBuffer:(void *)uvBuffer width:(int)width height:(int)height;

/**
 处理原始数据, 格式为I420, 一般用于安卓设备
 
 ----------plane0
 Y1 Y2 Y3 Y4
 Y5 Y6 Y7 Y8
 ----------plane1
 U1 U2
 ----------plane2
 V1 V2
 
 @param yBuffer 灰度数据
 @param uBuffer 色度数据
 @param vBuffer 色度数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithYBuffer:(void *)yBuffer uBuffer:(void *)uBuffer vBuffer:(void *)vBuffer width:(int)width height:(int)height;

/**
 处理原始数据, 格式为32BGRA
 */
- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height;

@end
