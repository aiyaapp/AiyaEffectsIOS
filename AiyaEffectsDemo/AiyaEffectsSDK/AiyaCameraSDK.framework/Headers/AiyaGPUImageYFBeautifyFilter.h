//
//  AiyaGPUImageYFBeautifyFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/21.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilter.h"

typedef NS_ENUM(NSInteger, AIYA_YF_BEAUTY_LEVEL) {
    AIYA_YF_BEAUTY_LEVEL_0,
    AIYA_YF_BEAUTY_LEVEL_1,
    AIYA_YF_BEAUTY_LEVEL_2,
    AIYA_YF_BEAUTY_LEVEL_3,
    AIYA_YF_BEAUTY_LEVEL_4,
    AIYA_YF_BEAUTY_LEVEL_5,
    AIYA_YF_BEAUTY_LEVEL_6
};

typedef NS_ENUM(NSUInteger, AIYA_YF_BEAUTY_TYPE) {
    AIYA_YF_BEAUTY_TYPE_0,
    AIYA_YF_BEAUTY_TYPE_1,
    AIYA_YF_BEAUTY_TYPE_4 = 4,
    AIYA_YF_BEAUTY_TYPE_5 = 5,
};

@interface AiyaGPUImageYFBeautifyFilter : AYGPUImageFilter

@property (nonatomic, assign) AIYA_YF_BEAUTY_LEVEL beautyLevel;

@property (nonatomic, assign) AIYA_YF_BEAUTY_TYPE beautyType;

@end
