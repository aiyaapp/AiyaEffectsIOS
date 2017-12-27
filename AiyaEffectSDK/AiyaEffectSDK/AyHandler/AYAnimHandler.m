//
//  AYAnimHandler.m
//  AiyaEffectSDK
//
//  Created by 汪洋 on 2017/12/27.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYAnimHandler.h"
#if AY_ENABLE_EFFECT
#import "AyEffect.h"
#endif

@interface AYAnimHandler ()
#if AY_ENABLE_EFFECT
@property (nonatomic, strong) AyEffect *effect;

@property (nonatomic, assign) NSInteger currentPlayCount;
#endif
@end

@implementation AYAnimHandler

- (instancetype)init
{
    self = [super init];
    if (self) {
#if AY_ENABLE_EFFECT
        _effect = [[AyEffect alloc] init];
        [self.effect initGLResource];
        self.effect.enalbeVFilp = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aiyaMessage:) name:AiyaMessageNotification object:nil];
#endif
    }
    return self;
}

- (void)processWithWidth:(GLint)width height:(GLint)height{
#if AY_ENABLE_EFFECT
    //------------->绘制图像<--------------//
    glEnable(GL_BLEND);
    
    [self.effect processWithTexture:0 width:width height:height];
    
    glDisable(GL_BLEND);
    //------------->绘制图像<--------------//
#endif
}

#if AY_ENABLE_EFFECT
- (void)setEffectPath:(NSString *)effectPath{
    _effectPath = effectPath;
    
    [self.effect setEffectPath:effectPath];
}

- (void)setEffectPlayCount:(NSUInteger)effectPlayCount{
    _effectPlayCount = effectPlayCount;
    self.currentPlayCount = 0;
}

- (void)aiyaMessage:(NSNotification *)notifi{
    NSString *message = notifi.userInfo[AiyaMessageNotificationUserInfoKey];
    
    if (!self.effectPath || [self.effectPath isEqualToString:@""]){
        
    }else if ([@"AY_EFFECTS_END" isEqualToString:message]) {//已经渲染完成一遍
        self.currentPlayCount ++;
        if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount){
            [self setEffectPath:@""];
            [[NSNotificationCenter defaultCenter] postNotificationName:AiyaMessageNotification object:nil userInfo:@{AiyaMessageNotificationUserInfoKey:@"AY_EFFECTS_REPLAY_END"}];
        }
    }else if (self.effectPlayCount != 0 && self.currentPlayCount >= self.effectPlayCount) {//已经播放完成
        [self setEffectPath:@""];
        [[NSNotificationCenter defaultCenter] postNotificationName:AiyaMessageNotification object:nil userInfo:@{AiyaMessageNotificationUserInfoKey:@"AY_EFFECTS_REPLAY_END"}];
    }
}
#endif

- (void)pauseEffect{
#if AY_ENABLE_EFFECT
    [self.effect pauseProcess];
#endif
}

- (void)resumeEffect{
#if AY_ENABLE_EFFECT
    [self.effect resumeProcess];
#endif
}

#if AY_ENABLE_EFFECT
- (void)dealloc{
    [self.effect releaseGLtContext];
}
#endif

@end
