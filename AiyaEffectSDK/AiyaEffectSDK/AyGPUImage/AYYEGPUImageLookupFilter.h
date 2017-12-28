//
//  AYYEGPUImageLookupFilter.h
//  AiyaVideoEffectSDK
//
//  Created by 汪洋 on 2017/11/21.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYYEGPUImageFilter.h"

@interface AYYEGPUImageLookupFilter : AYYEGPUImageFilter

@property (nonatomic, strong) UIImage* style;

@property (nonatomic, assign) CGFloat intensity;

@end
