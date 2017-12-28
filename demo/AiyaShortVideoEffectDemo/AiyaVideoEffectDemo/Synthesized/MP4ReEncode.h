//
//  Mp4Reencode.h
//  ReencodeMp4
//
//  Created by 汪洋 on 2017/9/27.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@protocol MP4ReEncodeDelegate <NSObject>
/**
 设置的参数
 @param naturalSize 视频的宽高
 @param preferredTransform 视频的旋转角度
 */
- (void)MP4ReEncodeVideoParamWithNaturalSize:(CGSize *) naturalSize preferredTransform:(CGAffineTransform *)preferredTransform;


/**
 重编码时的数据回调

 @param sampleBuffer 输入的数据
 @return 输出的数据
 */
- (CMSampleBufferRef)MP4ReEncodeProcessVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;


/**
 重编码结束

 @param success 编码是否成功
 */
- (void)MP4ReEncodeFinish:(bool)success;


@end

@interface MP4ReEncode : NSObject

@property (nonatomic, copy) NSURL *inputURL;
@property (nonatomic, copy) NSURL *outputURL;

@property (nonatomic, weak) id <MP4ReEncodeDelegate> delegate;

/**
 设置码率
 
 @param bitrate 码率
 */
- (void) SetBitrate:(unsigned int)bitrate;

/**
 初始化设置
 */
- (void)initSetup;

/**
 开始重编码
 */
- (void)startReencode;

/**
 重编码取消
 */
- (void)cancel;

@end
