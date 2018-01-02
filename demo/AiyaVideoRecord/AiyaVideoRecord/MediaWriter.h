#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MediaWriter : NSObject

/**
 设置视频保存位置
*/
@property (nonatomic, strong) NSURL *outputURL;

/**
 写音频数据
 */
- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 写视频数据
 */
- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;

/**
 写入完成
 */
- (void)finishWritingWithCompletionHandler:(void (^)(void))handler;

/**
 取消写入
 */
- (void)cancelWriting;

@end
