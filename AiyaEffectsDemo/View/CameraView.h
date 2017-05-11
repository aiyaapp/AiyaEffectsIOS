//
//  CameraView.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2017/3/9.
//  Copyright © 2016年 深圳哎吖科技. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AiyaCameraSDK/AiyaGPUImageBeautifyFilter.h>

@protocol CameraViewDelegate <NSObject>

- (void)onChangeCameraPosition:(AVCaptureDevicePosition)cameraPosition;

- (void)onEffectClick:(NSString *)path;

- (void)onBeautyTypeClick:(AIYA_BEAUTY_TYPE)beautyType;

- (void)onBeautyLevelChange:(AIYA_BEAUTY_LEVEL)beautyLevel;

@end

@interface CameraView : UIView

//data step 3 UIImage|Text|Path
@property (nonatomic, strong) NSArray *effectData;

//data step 3 UIImage|Text|Type
@property (nonatomic, strong) NSArray *beautifyData;

@property (nonatomic, weak) id<CameraViewDelegate> delegate;

@end
