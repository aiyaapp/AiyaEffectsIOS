//
//  AiyaBeautifyEffect.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/16.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AiyaBeautifyEffect : NSObject

- (void)initEffectContextWithWidth:(int)width height:(int)height;

- (void)beautifyFaceWithTexture:(GLuint)texture width:(int)width height:(int)height beautyLevel:(NSInteger) beautyLevel;

- (void)deinitEffectContext;


@end
