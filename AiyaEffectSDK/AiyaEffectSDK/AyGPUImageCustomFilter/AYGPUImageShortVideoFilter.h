//
//  AYGPUImageShortVideoFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/2.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

typedef NS_ENUM(NSUInteger, AY_VIDEO_EFFECT_TYPE) {
    AY_VIDEO_EFFECT_NONE = 0,            //0 基本特效
    AY_VIDEO_EFFECT_SPIRIT_FREED,        //1 灵魂出窍
    AY_VIDEO_EFFECT_SHAKE,               //2 抖动
    AY_VIDEO_EFFECT_BLACK_MAGIC,         //3 黑魔法
    AY_VIDEO_EFFECT_VIRTUAL_MIRROR,      //4 虚拟镜像
    AY_VIDEO_EFFECT_FLUORESCENCE,        //5 萤火
    AY_VIDEO_EFFECT_TIME_TUNNEL,         //6 时光隧道
    AY_VIDEO_EFFECT_DYSPHORIA,           //7 躁动
    AY_VIDEO_EFFECT_FINAL_ZELIG,         //8 终极变色
    AY_VIDEO_EFFECT_SPLIT_SCREEN,        //9 分屏
    AY_VIDEO_EFFECT_HALLUCINATION,       //10 幻觉
    AY_VIDEO_EFFECT_SEVENTYS,            //11 70s
    AY_VIDEO_EFFECT_ROLL_UP,             //12 炫酷转动
    AY_VIDEO_EFFECT_FOUR_SCREEN,         //13 四分屏
    AY_VIDEO_EFFECT_THREE_SCREEN,        //14 三分屏
    AY_VIDEO_EFFECT_BLACK_WHITE_TWINKLE, //15 黑白闪烁
};

@interface AYGPUImageShortVideoFilter : AYGPUImageFilter

@property (nonatomic, assign) AY_VIDEO_EFFECT_TYPE type;

/**
 设置参数
 
 1 灵魂出窍：
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 1.2 "MaxScalingRatio"——虚影缩放参数；取值范围[0.0f, 0.8f]
 1.3 "WaitTime"——停留时间（无特效），取值范围[0.0f, inf]
 1.4 "ShadowAlpha"——虚影透明度，取值范围[0.1f,0.5f]
 
 2 抖动：
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 1.2 "MaxScalingRatio"——虚影缩放参数；取值范围[0.0f, 0.8f]
 1.3 "WaitTime"——停留时间（无特效），取值范围[0.0f, inf]
 
 3 Black Magic
 1.1 "Scale"——尺度，取值范围[1.0f, 5.0f]
 
 4 虚拟镜像
 无可配置参数
 
 5——荧光
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 
 6——时光隧道
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 
 7——躁动
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 
 8——终极变色
 1.1 "LastTime"——特效持续帧数，取值范围[3.0f, inf]
 
 9——分屏
 1.1 "SpliteSizeX"——x方向子屏幕的个数，取值范围[1, 5]
 1.2 "SpliteSizeY"——y方向子屏幕的个数，取值范围[1, 5]
 
 10——幻觉
 无可配置参数
 
 11——70S
 无可配置参数
 
 12——分屏转动
 1.1 "SpliteSizeX"——x方向子屏幕的个数，取值范围[1, 5]
 1.2 "SpliteSizeY"——y方向子屏幕的个数，取值范围[1, 5]
 1.3 "ClockWise"——旋转方向，取值范围0或者1
 1.4 "RollStepX"——x方向旋转速度，取值范围[1, 100]
 1.5 "RollStepY"——y方向旋转速度，取值范围[1, 100]
 
 13——四分屏
 1.1 "Interval"——每个子屏幕的绘制时间，小于等于0表示不切换子屏幕。
 
 14——三分屏
 1.1 "Interval"——每个子屏幕的绘制时间，小于等于0表示不切换子屏幕。
 
 15——黑白闪烁
 1.1 "TwinkleTime"——黑白闪烁的时间，取值范围[0,inf]
 1.2 "TotalTime"——总时间=黑白闪烁时间+不进行黑白闪烁的时间，取值范围[1,inf]
 
 */
- (void)setFloatValue:(CGFloat)value forKey:(NSString *)key;

/**
 重新效果
 */
- (void)reset;
@end
