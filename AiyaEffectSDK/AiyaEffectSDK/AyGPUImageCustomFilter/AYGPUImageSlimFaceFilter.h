//
//  AYGPUImageSlimFaceFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/30.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

@interface AYGPUImageSlimFaceFilter : AYGPUImageFilter

@property (nonatomic, assign) CGFloat intensity;

@property (nonatomic, assign) void **faceData;

@end
