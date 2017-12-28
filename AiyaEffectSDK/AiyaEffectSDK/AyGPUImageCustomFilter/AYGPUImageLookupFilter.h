//
//  AYGPUImageLookupFilter.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageFilter.h"

@interface AYGPUImageLookupFilter : AYGPUImageFilter

@property (nonatomic, strong) UIImage* lookup;

@property (nonatomic, assign) CGFloat intensity;

@end
