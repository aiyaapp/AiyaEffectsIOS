//
//  AiyaGPUImageTrackFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2016/10/27.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilter.h"
#import "AiyaCameraEffect.h"

@interface AiyaGPUImageTrackFilter : NSObject <AYGPUImageInput>

- (id)initWithAiyaCameraEffect:(AiyaCameraEffect *)cameraEffect;

@end
