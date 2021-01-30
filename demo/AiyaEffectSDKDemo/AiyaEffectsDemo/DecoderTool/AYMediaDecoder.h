//
//  AYMediaDecoder.h
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/25.
//  Copyright © 2021 深圳哎吖科技. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@protocol AYMediaDecoderDelegate

- (void)decoderOutputVideoFormatWithWidth:(NSUInteger)width height:(NSUInteger)height videoFrameRate:(NSUInteger)videoFrameRate transform:(CGAffineTransform)transform;

- (void)decoderOutputAudioFormatWithChannelCount:(NSUInteger)channelCount sampleRate:(NSUInteger)sampleRate;

- (void)decoderVideoOutput:(CMSampleBufferRef)sampleBuffer;

- (void)decoderAudioOutput:(CMSampleBufferRef)sampleBuffer;

- (void)decoderVideoEOS:(BOOL)success;

- (void)decoderAudioEOS:(BOOL)success;

@end

@interface AYMediaDecoder : NSObject

@property(nonatomic, weak) id<AYMediaDecoderDelegate> delegate;

/**
 设置音视频路径
 */
- (void)setOutputMediaURL:(NSURL *)outputMediaURL completion:(void (^)(bool))completion;

/**
 配置视频解码
 */
- (void)configureVideoDecoder;

/**
 配置音频解码
 */
- (void)configureAudioDecoder;

/**
 启动解码器
 */
- (void)start;

/**
 取消读取
 */
- (void)cancelReading;

/**
 旋转矩阵转旋转角度
 */
+ (NSUInteger)preferredTransformToRotation:(CGAffineTransform)transform;

@end
