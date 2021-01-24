//
//  AYCamera.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2019/12/11.
//  Copyright © 2019 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol AYCameraDelegate <NSObject>
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

@interface AYCamera : NSObject

/**
 输出设备, 输出视频数据 (CMSampleBufferRef)
 */
@property (nonatomic, strong, readonly) AVCaptureVideoDataOutput *videoOutput;
/**
 输出设备, 输出音频数据 (CMSampleBufferRef)
 */
@property (nonatomic, strong, readonly) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, weak) id <AYCameraDelegate> delegate;

/**
 设置前后相机
 */
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;

/**
 初始化指定分辨率的相机
 */
- (instancetype)initWithResolution:(AVCaptureSessionPreset)resolution;

/**
 设置帧率
 */
- (void)setFrameRate:(int)rate;

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
