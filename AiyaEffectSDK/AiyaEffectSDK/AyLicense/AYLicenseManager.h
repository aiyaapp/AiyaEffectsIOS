//
//  AYLicenseManager.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/29.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AYAuthCallback)(int);

@interface AYLicenseManager : NSObject

/**
 初始化lisence
 异步请求服务器确认lisence
 */
+ (void)initLicense:(NSString *)appKey callback:(AYAuthCallback)callback;

@end
