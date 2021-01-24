//
//  AyCore.m
//  AyCore
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AyCore.h"
#include "AyObserver.h"
#include "AyCoreAuth.h"
#include "AYEffectConstants.h"

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>

AYAuthCallback authCallback = nil;

void func_ay_auth_message(int type, int ret, const char *info) {
    if (type == AyObserverMsg::MSG_TYPE_AUTH) {
        
        if (authCallback != nil) {
            authCallback(ret);
            authCallback = nil;
        }
    }
}

AyObserver ay_auth_observer = {func_ay_auth_message};

@implementation AyCore

+ (void)initLicense:(NSString *)appKey callback:(AYAuthCallback)callback {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        authCallback = [callback copy];
        AyCore_Auth("", "", std::string(appKey.UTF8String), "", &ay_auth_observer);
    });
}

@end
