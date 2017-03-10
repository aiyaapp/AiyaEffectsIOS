//
//  AiyaCameraEffect.h
//  AiyaCameraSDKDemo
//
//  哎吖相机特效
//
//  Created by 汪洋 on 2016/10/26.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AiyaCameraEffect : NSObject

@property (nonatomic, copy) NSString *effectPath;

- (void)initEffectContextWithWidth:(int)width height:(int)height;

- (void)trackFaceWithByteBuffer:(GLubyte *)byteBuffer width:(int)width height:(int)height;

- (void)beautifyFaceWithTexture:(GLuint)texture width:(int)width height:(int)height beautyLevel:(NSInteger) beautyLevel;

- (int)processWithTexture:(GLuint)texture width:(int)width height:(int)height;

- (void)deinitEffectContext;

@end
