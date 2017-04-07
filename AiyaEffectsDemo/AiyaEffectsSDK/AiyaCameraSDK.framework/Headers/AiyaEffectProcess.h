//
//  AiyaEffectProcess.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/23.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AiyaCameraSDK/AiyaGPUImageBeautifyFilter.h>
#import <AiyaCameraSDK/AiyaGPUImageEffectFilter.h>

@interface AiyaEffectProcess : NSObject

/**
 设置美颜等级
 */
@property (nonatomic, assign) AIYA_BEAUTY_LEVEL beautyLevel;

/** 
 设置美颜类型 默认0 
 */
@property (nonatomic, assign) AIYA_BEAUTY_TYPE beautyType;

/**
 设置特效,通过设置特效文件路径的方式,默认空值,空值表示取消渲染特效
 */
@property (nonatomic, copy) NSString *effectPath;

/**
 设置特效播放次数,默认0,0表示一直重复播放当前特效
 */
@property (nonatomic, assign) NSUInteger effectPlayCount;

/**
 使用设置的特效对图像数据进行处理

 @param pixelBuffer 图像数据
 @return 特效播放状态
 */
- (AIYA_EFFECT_STATUS)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
