//
//  AYMediaEncoder.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/21.
//  Copyright © 2021年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 音视频存储
 */
@interface AYMediaEncoder : NSObject

/**
 设置音视频保存位置
 */
- (BOOL)setOutputMediaURL:(NSURL *)outputMediaURL;

/**
 配置视频编码
 */
- (BOOL)configureVideoEncoderWithWidth:(NSUInteger)width height:(NSUInteger)height videoBitRate:(NSUInteger)videoBitRate videoFrameRate:(NSUInteger)videoFrameRate transform:(CGAffineTransform)transform pixelFormatType:(OSType)pixelFormatType;

/**
 配置音频编码
 */
- (BOOL)configureAudioEncoderWithChannelCount:(NSUInteger)channelCount sampleRate:(NSUInteger)sampleRate audioBitRate:(NSUInteger)audioBitRate;

/**
 启动编码器
 */
- (BOOL)start;

/**
 写视频数据
 */
- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;

/**
 写音频数据
 */
- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 写入完成
 */
- (void)finishWritingWithCompletionHandler:(void (^)(void))handler;

/**
 取消写入
 */
- (void)cancelWriting;

@end

@interface AYMediaWriterTool : NSObject

/**
 44100采样率的PCM数据转成SampleBuffer
 */
+ (CMSampleBufferRef)PCMDataToSampleBuffer:(NSData *)pcmData pts:(CMTime)pts duration:(CMTime)duration;

@end
