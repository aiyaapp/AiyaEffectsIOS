//
//  AyShortVideoEffect.h
//  AyShortVideoEffect
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface AyShortVideoEffect : NSObject

/**
 短视频类型
 */
- (instancetype)initWithType:(NSInteger)type;

/**
 初始化opengl相关的资源
 */
- (void)initGLResource;

/**
 释放opengl相关的资源
 */
- (void)releaseGLResource;

/**
 设置参数
 */
- (void)setFloatValue:(CGFloat)value forKey:(NSString *)key;

/**
 绘制特效
 
 @param texture 纹理数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height;

/**
 重置特效
 */
- (void)reset;

@end
