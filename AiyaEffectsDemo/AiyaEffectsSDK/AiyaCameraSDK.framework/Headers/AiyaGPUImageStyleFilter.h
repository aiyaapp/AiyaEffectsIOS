//
//  AiyaGPUImageStyleFilter.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/22.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import "AYGPUImageFilterGroup.h"
@class AYGPUImagePicture;

@interface AiyaGPUImageStyleFilter : AYGPUImageFilterGroup{
    AYGPUImagePicture *lookupImageSource;
}

@property (nonatomic, strong) UIImage* style;

@property (nonatomic, assign) CGFloat intensity;

@end
