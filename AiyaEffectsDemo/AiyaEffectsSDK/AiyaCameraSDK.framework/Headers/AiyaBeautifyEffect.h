//
//  AiyaBeautifyEffect.h
//  AiyaCameraSDK
//
//  Created by 汪洋 on 2017/2/16.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AiyaBeautifyEffect : NSObject

/**
 初始化上下文

 @param width 保留字段,传0
 @param height 保留字段,传0
 */
- (void)initEffectContextWithWidth:(int)width height:(int)height;


/**
 对纹理数据进行美颜

 @param texture 需要美颜的纹理数据
 @param width 纹理数据宽度
 @param height 纹理数据高度
 @param beautyType 美颜类型
 @param beautyLevel 美颜等级
 */
- (void)beautifyFaceWithTexture:(GLuint)texture width:(int)width height:(int)height beautyType:(NSUInteger)beautyType beautyLevel:(NSInteger) beautyLevel;


/**
 销毁上下文
 */
- (void)deinitEffectContext;


@end
