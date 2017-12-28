//
//  AySlimFace.h
//  AyBeauty
//
//  Created by 汪洋 on 2017/12/1.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AySlimFace : NSObject

/**
 瘦脸强度 [0.0f, 1.0f]
*/
@property (nonatomic, assign) CGFloat intensity;

/**
 人脸数据
 */
@property (nonatomic, assign) void *faceData;

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
