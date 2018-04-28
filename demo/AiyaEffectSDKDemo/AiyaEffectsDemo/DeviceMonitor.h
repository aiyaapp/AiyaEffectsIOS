//
//  DeviceMonitor.h
//  AiyaCameraSDKTest
//
//  Created by 汪洋 on 2017/3/22.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceMonitor : NSObject

vm_size_t usedMemory(void);
vm_size_t freeMemory(void);
float cpuUsage();

@end
