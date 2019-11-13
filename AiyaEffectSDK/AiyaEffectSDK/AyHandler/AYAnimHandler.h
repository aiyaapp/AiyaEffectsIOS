//
//  AYAnimHandler.h
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/27.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@protocol AYAnimHandlerDelegate <NSObject>

/**
 播放结束
 */
- (void)playEnd;

@end

@interface AYAnimHandler : NSObject

@property (nonatomic, weak) id<AYAnimHandlerDelegate> delegate;

/**
 设置特效,通过设置特效文件路径的方式,默认空值,空值表示取消渲染特效
 */
@property (nonatomic, strong) NSString *effectPath;

/**
 设置特效播放次数
 */
@property (nonatomic, assign) NSUInteger effectPlayCount;

/**
 暂停特效播放
 */
- (void)pauseEffect;

/**
 继续特效播放
 */
- (void)resumeEffect;

/**
 绘制动画
 
 @param width 宽度
 @param height 高度
 */
- (void)processWithWidth:(GLint)width height:(GLint)height;

@end
