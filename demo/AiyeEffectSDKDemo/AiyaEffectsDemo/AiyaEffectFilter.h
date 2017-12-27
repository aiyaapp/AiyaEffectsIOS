//
//  AiyaEffectFilter.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/12/3.
//  Copyright © 2017年 深圳哎吖科技. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface AiyaEffectFilter : GPUImageFilter

- (void)setEffect:(NSString *)path;

- (void)setEffectCount:(NSUInteger)effectCount;

- (void)pauseEffect;

- (void)resumeEffect;

- (void)setSmooth:(CGFloat)intensity;

- (void)setSaturation:(CGFloat)intensity;

- (void)setWhiten:(CGFloat)intensity;

- (void)setBigEye:(CGFloat)intentsity;

- (void)setSlimFace:(CGFloat)intentsity;

- (void)setStyle:(UIImage *)style;

- (void)setIntensityOfStyle:(CGFloat)intensity;

@end
