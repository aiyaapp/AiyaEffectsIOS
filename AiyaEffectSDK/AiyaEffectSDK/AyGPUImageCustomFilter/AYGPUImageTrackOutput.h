//
//  AYGPUImageTrackOutput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/1.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AYGPUImageFilter.h"
#import "AYGPUImageContext.h"

@interface AYGPUImageTrackOutput : NSObject<AYGPUImageInput>

@property (nonatomic, assign) void **faceData;

- (instancetype)initWithContext:(AYGPUImageContext *)context;

@end
