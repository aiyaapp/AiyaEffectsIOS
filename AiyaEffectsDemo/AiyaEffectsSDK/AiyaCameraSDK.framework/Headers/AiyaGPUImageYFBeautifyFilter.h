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
    AIYA_YF_BEAUTY_LEVEL_6,
    AIYA_YF_BEAUTY_LEVEL_7,
    AIYA_YF_BEAUTY_LEVEL_8,
    AIYA_YF_BEAUTY_LEVEL_9,
    AIYA_YF_BEAUTY_LEVEL_10,
    AIYA_YF_BEAUTY_LEVEL_11,
};

@interface AiyaGPUImageYFBeautifyFilter : AYGPUImageFilter

@property (nonatomic, assign) AIYA_YF_BEAUTY_LEVEL beautyLevel;
@end
