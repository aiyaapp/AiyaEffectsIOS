//
//  AiyaGPUImageEffectFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2016/10/27.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilter.h"
#import "AiyaCameraEffect.h"

typedef NS_ENUM(NSUInteger, AIYA_EFFECT_STATUS) {
    AIYA_EFFECT_STATUS_INIT, /** 没有设置任何特效 */
    AIYA_EFFECT_STATUS_PLAYING, /** 特效播放中 */
    AIYA_EFFECT_STATUS_PLAYEND /** 特效播放结束 */
};

@interface AiyaGPUImageEffectFilter : AYGPUImageFilter

@property (nonatomic, copy) NSString *effectPath;

@property (nonatomic, assign) NSUInteger effectPlayCount;

@property (nonatomic, assign, readonly) int effectStatus;

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect;

@end
