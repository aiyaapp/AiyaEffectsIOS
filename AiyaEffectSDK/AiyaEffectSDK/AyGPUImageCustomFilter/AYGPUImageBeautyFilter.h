//
//  AYGPUImageBeautyFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/30.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

@interface AYGPUImageBeautyFilter : AYGPUImageFilter

typedef NS_ENUM(NSUInteger, AY_BEAUTY_TYPE) {
    AY_BEAUTY_TYPE_0 = 0x1000,
    AY_BEAUTY_TYPE_2 = 0x1002,
    AY_BEAUTY_TYPE_3 = 0x1003,
    AY_BEAUTY_TYPE_4 = 0x1004,
    AY_BEAUTY_TYPE_5 = 0x1005,
    AY_BEAUTY_TYPE_6 = 0x1006
};


/**
 美颜算法类型
 */
@property (nonatomic, assign) AY_BEAUTY_TYPE type;

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
 美白 [0.0f, 1.0f], 只适用于 0x1003, 0x1004, 0x1005, 0x1006
 */
@property (nonatomic, assign) CGFloat whiten;


/**
 初始化美颜

 @param context GPUImage上下文
 @param type 美颜算法
 @return 指定美颜算法的美颜Filter
 */
- (id)initWithContext:(AYGPUImageContext *)context type:(AY_BEAUTY_TYPE)type;

@end
