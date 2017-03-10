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

/** 美颜等级 */
@property (nonatomic, assign) AIYA_BEAUTY_LEVEL beautyLevel;

/** 特效资源路径 默认空值 空值表示取消渲染特效  */
@property (nonatomic, copy) NSString *effectPath;

/** 特效播放次数 默认0 0表示一直渲染当前特效 */
@property (nonatomic, assign) NSUInteger effectPlayCount;

/** 处理数据 */
- (AIYA_EFFECT_STATUS)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end
