//
//  AyBeauty.h
//  AyBeauty
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface AyBeauty : NSObject

/**
 美颜类型取值 {0x1000, 0x1002, 0x1003, 0x1004, 0x1005, 0x1006}
 */
- (instancetype)initWithType:(NSInteger)type;

/**
 美颜类型
 */
@property (nonatomic, assign, readonly) CGFloat type;

/**
 美颜强度 [0.0f, 1.0f], 只适用于 0x1002
 */
@property (nonatomic, assign) CGFloat intensity;

/**
 磨皮 [0.0f, 1.0f], 只适用于 0x1000, 0x1003, 0x1004, 0x1005, 0x1006
 */
@property (nonatomic, assign) CGFloat smooth;

/**
 饱和度 [0.0f, 1.0f], 只适用于 0x1000, 0x1003, 0x1004, 0x1005
 */
@property (nonatomic, assign) CGFloat saturation;

/**
 亮度 [0.0f, 1.0f], 只适用于 0x1003, 0x1004, 0x1005, 0x1006
 */
@property (nonatomic, assign) CGFloat whiten;

/**
 初始化opengl相关的资源
 */
- (void)initGLResource;

/**
 释放opengl相关的资源
 */
- (void)releaseGLResource;

/**
 绘制特效
 
 @param texture 纹理数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithTexture:(GLuint)texture width:(GLuint)width height:(GLuint)height;

@end
