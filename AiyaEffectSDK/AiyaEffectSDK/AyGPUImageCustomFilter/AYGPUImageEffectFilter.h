//
//  AYGPUImageEffectFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

@interface AYGPUImageEffectFilter : AYGPUImageFilter

@property (nonatomic, strong) NSString *effectPath;

@property (nonatomic, assign) NSUInteger effectPlayCount;

@property (nonatomic, assign) void **faceData;

- (void)pause;

- (void)resume;

@end
