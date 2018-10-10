//
//  AyCore.h
//  AyCore
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const AiyaLicenseNotification;
extern NSString * const AiyaLicenseNotificationUserInfoKey;

@interface AyCore : NSObject

/**
 初始化lisence
 异步请求服务器确认lisence
 */
+ (void)initLicense:(NSString *)appKey;

@end
