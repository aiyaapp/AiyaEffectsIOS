//
//  AyCoreAuth.h
//  AiyaVideoEffectSDK
//
//  Created by 汪洋 on 2017/11/20.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#ifndef AIYASDK_AYCOREAUTH_H
#define AIYASDK_AYCOREAUTH_H
#include <string>
#include "AyObserver.h"

#ifdef __cplusplus
extern "C"
{
#endif
    
    void AyCore_Release();
    
    void AyCore_Auth(std::string path, std::string appId, std::string appKey, std::string imei, AyObserver * observer);
    
#ifdef __cplusplus
};
#endif
#endif //AIYASDK_AYCOREAUTH_H

