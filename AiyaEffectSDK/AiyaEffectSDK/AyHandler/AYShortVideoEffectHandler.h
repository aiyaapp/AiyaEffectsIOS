//
//  AYShortVideoEffectHandler.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/2.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "AYGPUImageConstants.h"

typedef NS_ENUM(NSUInteger, AY_SHORT_VIDEO_EFFECT_TYPE) {
    AY_SHORT_VIDEO_EFFECT_NONE = 0,            // 基本特效
    AY_SHORT_VIDEO_EFFECT_SPIRIT_FREED,        // 灵魂出窍
    AY_SHORT_VIDEO_EFFECT_SHAKE,               // 抖动
    AY_SHORT_VIDEO_EFFECT_BLACK_MAGIC,         // 黑魔法
    AY_SHORT_VIDEO_EFFECT_VIRTUAL_MIRROR,      // 虚拟镜像
    AY_SHORT_VIDEO_EFFECT_FLUORESCENCE,        // 萤火
    AY_SHORT_VIDEO_EFFECT_TIME_TUNNEL,         // 时光隧道
    AY_SHORT_VIDEO_EFFECT_DYSPHORIA,           // 躁动
    AY_SHORT_VIDEO_EFFECT_FINAL_ZELIG,         // 终极变色
    AY_SHORT_VIDEO_EFFECT_SPLIT_SCREEN,        // 分屏
    AY_SHORT_VIDEO_EFFECT_HALLUCINATION,       // 幻觉
    AY_SHORT_VIDEO_EFFECT_SEVENTYS,            // 70s
    AY_SHORT_VIDEO_EFFECT_ROLL_UP,             // 炫酷转动
    AY_SHORT_VIDEO_EFFECT_FOUR_SCREEN,         // 四分屏
    AY_SHORT_VIDEO_EFFECT_THREE_SCREEN,        // 三分屏
    AY_SHORT_VIDEO_EFFECT_BLACK_WHITE_TWINKLE, // 黑白闪烁
    AY_SHORT_VIDEO_EFFECT_PLACE_HOLDER
};

@interface AYShortVideoEffectHandler : NSObject

/**
 特效类型
 */
@property (nonatomic, assign) AY_SHORT_VIDEO_EFFECT_TYPE type;

/**
 设置特效旋转或者翻转, 共8个方向
 */
@property (nonatomic, assign) AYGPUImageRotationMode rotateMode;

/**
 处理纹理数据
 
 @param texture 纹理数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithTexture:(GLuint)texture width:(GLint)width height:(GLint)height;

/**
 清空所有资源
 */
- (void)destroy;

@end
