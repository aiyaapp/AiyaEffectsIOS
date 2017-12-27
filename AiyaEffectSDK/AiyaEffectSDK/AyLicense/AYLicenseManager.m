//
//  AYLicenseManager.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYLicenseManager.h"
#import "AySDKCore.h"

@implementation AYLicenseManager

+ (void)initLicense:(NSString *)appKey{
    [AySDKCore initLicense:appKey];
}

@end
