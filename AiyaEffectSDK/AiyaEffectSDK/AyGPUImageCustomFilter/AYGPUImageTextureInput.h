//
//  AYGPUImageTextureInput.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/11/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYGPUImageOutput.h"

@interface AYGPUImageTextureInput : AYGPUImageOutput

@property (nonatomic, assign) BOOL verticalFlip;

- (void)processBGRADataWithTexture:(GLint)texture width:(int)width height:(int)height;

@end
