//
//  AiyaGPUImageBeautifyFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2016/12/14.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilter.h"
#import "AiyaCameraEffect.h"

typedef NS_ENUM(NSInteger, AIYA_BEAUTY_LEVEL) {
    AIYA_BEAUTY_LEVEL_0,
    AIYA_BEAUTY_LEVEL_1,
    AIYA_BEAUTY_LEVEL_2,
    AIYA_BEAUTY_LEVEL_3,
    AIYA_BEAUTY_LEVEL_4,
    AIYA_BEAUTY_LEVEL_5,
    AIYA_BEAUTY_LEVEL_6
};

typedef NS_ENUM(NSUInteger, AIYA_BEAUTY_TYPE) {
    AIYA_BEAUTY_TYPE_0,
    AIYA_BEAUTY_TYPE_1 = 1,
    AIYA_BEAUTY_TYPE_4 = 4,
    AIYA_BEAUTY_TYPE_5 = 5,
};

@interface AiyaGPUImageBeautifyFilter : AYGPUImageFilter

@property (nonatomic, assign) AIYA_BEAUTY_LEVEL beautyLevel;

@property (nonatomic, assign) AIYA_BEAUTY_TYPE beautyType;

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect;

@end
