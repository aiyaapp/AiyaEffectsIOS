//
//  Camera.h
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraDelegate <NSObject>
@optional

/**
 视频数据回调 BGRA格式

 @param sampleBuffer 数据
 */
- (void)cameraVideoOutput:(CMSampleBufferRef)sampleBuffer;

/**
 音频数据回调

 @param sampleBuffer 数据
 */
- (void)cameraAudioOutput:(CMSampleBufferRef)sampleBuffer;

@end

@interface Camera : NSObject

@property (nonatomic, weak) id <CameraDelegate> delegate;

/**
 设置前后相机
 */
- (void)setCameraPosition:(AVCaptureDevicePosition)position;

/**
 设置帧率
 */
- (void)setRate:(int)rate;

/**
 设置手电筒
 */
- (void)setTorchOn:(BOOL)torchMode;

/**
 设置焦点
 */
- (void)focusAtPoint:(CGPoint)focusPoint;

/**
 打开相机, 麦克风
 */
- (void)startCapture;

/**
 关闭相机, 麦克风
 */
- (void)stopCapture;

@end
