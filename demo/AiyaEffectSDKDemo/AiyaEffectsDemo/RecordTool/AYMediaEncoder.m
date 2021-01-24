//
//  AYMediaEncoder.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/21.
//  Copyright © 2021年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "AYMediaEncoder.h"
#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface AYMediaEncoder ()

@property (nonatomic, strong) AVAssetWriter *assetMediaWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdapter;

@property (nonatomic, assign) BOOL isFinish;

@property (nonatomic, assign) CMTime firstTime;

@property (nonatomic, strong) dispatch_queue_t encoderQueue;

- (NSArray *)_metadataArray;

@end

@implementation AYMediaEncoder

#pragma mark - init

- (id)init{
    self = [super init];
    if (self) {
        _encoderQueue = dispatch_queue_create("com.wenyao.videorecord", DISPATCH_QUEUE_CONCURRENT);
        _firstTime = kCMTimeZero;
    }
    return self;
}

- (BOOL)setOutputMediaURL:(NSURL *)outputMediaURL {
    NSError *error = nil;
    _assetMediaWriter = [AVAssetWriter assetWriterWithURL:outputMediaURL fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"error setting up the asset writer (%@)", error);
        self.assetMediaWriter = nil;
        return NO;
    }
    
    self.assetMediaWriter.shouldOptimizeForNetworkUse = YES;
    self.assetMediaWriter.metadata = [self _metadataArray];
    
    _isFinish = NO;
    return YES;
}

#pragma mark - private

- (NSArray *)_metadataArray{
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    
    // device model
    AVMutableMetadataItem *modelItem = [[AVMutableMetadataItem alloc] init];
    [modelItem setKeySpace:AVMetadataKeySpaceCommon];
    [modelItem setKey:AVMetadataCommonKeyModel];
    [modelItem setValue:[currentDevice localizedModel]];
    
    // creation date
    AVMutableMetadataItem *creationDateItem = [[AVMutableMetadataItem alloc] init];
    [creationDateItem setKeySpace:AVMetadataKeySpaceCommon];
    [creationDateItem setKey:AVMetadataCommonKeyCreationDate];
    [creationDateItem setValue:[AYMediaEncoder AiyaVideoFormattedTimestampStringFromDate:[NSDate date]]];
    
    return @[modelItem, creationDateItem];
}

#pragma mark - setup

- (BOOL)configureAudioEncodeWithChannelCount:(NSUInteger)channelCount sampleRate:(NSUInteger)sampleRate audioBitRate:(NSUInteger)audioBitRate {
    
    AudioChannelLayout acl;
    bzero(&acl, sizeof(AudioChannelLayout));
    if (channelCount == 1) {
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    } else if (channelCount == 2) {
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    }
    
    NSDictionary *settings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                AVNumberOfChannelsKey : @(channelCount),
                                AVSampleRateKey :  @(sampleRate),
                                AVEncoderBitRateKey : @(audioBitRate),
                                AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(AudioChannelLayout)] };
    
    if (!self.assetWriterAudioInput && [self.assetMediaWriter canApplyOutputSettings:settings forMediaType:AVMediaTypeAudio]) {
        
        self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
        
        if (self.assetWriterAudioInput && [self.assetMediaWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetMediaWriter addInput:self.assetWriterAudioInput];
        } else {
            NSLog(@"couldn't add asset writer audio input");
            self.assetWriterAudioInput = nil;
            return NO;
        }
        
    } else {
        
        self.assetWriterAudioInput = nil;
        NSLog(@"couldn't apply audio output settings");
        return NO;
    }
    
    return YES;
}

- (BOOL)configureVideoEncodeWithWidth:(NSUInteger)width height:(NSUInteger)height videoBitRate:(NSUInteger)videoBitRate videoFrameRate:(NSUInteger)videoFrameRate transform:(CGAffineTransform)transform pixelFormatType:(OSType)pixelFormatType {
    
    NSDictionary *settings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                AVVideoWidthKey : @(width),
                                AVVideoHeightKey : @(height),
                                AVVideoCompressionPropertiesKey : @{
                                        AVVideoAverageBitRateKey : @(videoBitRate),
                                        AVVideoExpectedSourceFrameRateKey : @(videoFrameRate),
                                        AVVideoMaxKeyFrameIntervalKey : @(videoFrameRate)
                                }
    };
    
    if (!self.assetWriterVideoInput && [self.assetMediaWriter canApplyOutputSettings:settings forMediaType:AVMediaTypeVideo]) {
        
        self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = transform;
        
        if (self.assetWriterVideoInput && [self.assetMediaWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetMediaWriter addInput:self.assetWriterVideoInput];
        } else {
            
            self.assetWriterVideoInput = nil;
            NSLog(@"couldn't add asset writer video input");
            return NO;
        }
        
    } else {
        
        self.assetWriterVideoInput = nil;
        NSLog(@"couldn't apply video output settings");
        return NO;
    }
    
    self.pixelBufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.assetWriterVideoInput sourcePixelBufferAttributes:@{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(pixelFormatType)}];
    
    return YES;
}

- (BOOL)start {
    if (self.assetMediaWriter.status == AVAssetWriterStatusUnknown ) {
        return [self.assetMediaWriter startWriting];
    } else {
        return false;
    }
}

#pragma mark - sample buffer writing

- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (self.isFinish) {
        return;
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    
    // setup the writer
    if ( self.assetMediaWriter.status == AVAssetWriterStatusUnknown ) {
        NSLog(@"audio writer unknown");
        return;
    }
    
    // check for completion state
    if ( self.assetMediaWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"audio writer failure, (%@)", self.assetMediaWriter.error.localizedDescription);
        return;
    }
    
    if (self.assetMediaWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"audio writer cancelled");
        return;
    }
    
    if ( self.assetMediaWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }
    
    // perform write
    if ( self.assetMediaWriter.status == AVAssetWriterStatusWriting && CMTimeCompare(self.firstTime, kCMTimeZero) != 0) {
        
        CFRetain(sampleBuffer);
        
        dispatch_async(self.encoderQueue, ^{
            if (self.assetWriterAudioInput && self.assetWriterAudioInput.readyForMoreMediaData && !self.isFinish) {
                
                CMSampleBufferRef adjustedSampleBuffer = [self adjustTime:sampleBuffer by:self.firstTime];
                
                if (adjustedSampleBuffer ) {
                    if (![self.assetWriterAudioInput appendSampleBuffer:adjustedSampleBuffer]) {
                        NSLog(@"audio writer error appending audio (%@)", self.assetMediaWriter.error);
                    }else {
                        NSLog(@"audio write success");
                    }
                    
                    CFRelease(adjustedSampleBuffer);
                }
            }
            CFRelease(sampleBuffer);
        });
    }
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++){
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime {
    if (self.isFinish) {
        return;
    }
    
    // check for completion state
    if ( self.assetMediaWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"video writer failure, (%@)", self.assetMediaWriter.error.localizedDescription);
        return;
    }
    
    if (self.assetMediaWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"video writer cancelled");
        return;
    }
    
    if ( self.assetMediaWriter.status == AVAssetWriterStatusCompleted) {
        NSLog(@"video writer completed");
        return;
    }
    
    // perform write
    if (self.assetMediaWriter.status == AVAssetWriterStatusWriting) {
        
        CVPixelBufferRetain(pixelBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        
        dispatch_async(self.encoderQueue, ^{
            if (![self.assetWriterVideoInput isReadyForMoreMediaData] && !self.isFinish) {
                [NSThread sleepForTimeInterval: 0.01];
            }
            if ([self.assetWriterVideoInput isReadyForMoreMediaData] && !self.isFinish) {
                
                if (CMTimeCompare(self.firstTime, kCMTimeZero) == 0) {
                    self.firstTime = frameTime;
                    [self.assetMediaWriter startSessionAtSourceTime:kCMTimeZero];
                    NSLog(@"设置第一帧的时间");
                }
                
                CMTime videoTime = CMTimeSubtract(frameTime, self.firstTime);
                
                if (![self.pixelBufferAdapter appendPixelBuffer:pixelBuffer withPresentationTime:videoTime]) {
                    NSLog(@"video writer error appending video (%@)", self.assetMediaWriter.error);
                } else {
                    NSLog(@"video write success");
                }
                
            }
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CVPixelBufferRelease(pixelBuffer);
        });
        
    }
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler{
    dispatch_barrier_async(self.encoderQueue, ^{ //等待数据全部完成写入
        
        self.isFinish = YES;
        self.firstTime = kCMTimeZero;
        
        if (self.assetMediaWriter.status == AVAssetWriterStatusUnknown ||
            self.assetMediaWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset video writer was in an unexpected state (%@)", @(self.assetMediaWriter.status));
            handler();
            return;
        }
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];
        
        [self.assetMediaWriter finishWritingWithCompletionHandler:handler];
        
        self.assetWriterVideoInput = nil;
        self.assetWriterAudioInput = nil;
        
        self.assetMediaWriter = nil;
    });
}

- (void)cancelWriting{
    dispatch_barrier_async(self.encoderQueue, ^{//等待数据全部完成写入
        if (self.isFinish) {
            return;
        }
        
        self.isFinish = YES;
        self.firstTime = kCMTimeZero;
        
        if (self.assetMediaWriter.status == AVAssetWriterStatusUnknown ||
            self.assetMediaWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset video writer was in an unexpected state (%@)", @(self.assetMediaWriter.status));
            return;
        }
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];
        
        [self.assetMediaWriter cancelWriting];
        
        self.assetWriterAudioInput = nil;
        self.assetWriterVideoInput = nil;
        
        self.assetMediaWriter = nil;
        self.assetMediaWriter = nil;
    });
}

+ (NSString *)AiyaVideoFormattedTimestampStringFromDate:(NSDate *)date{
    if (!date)
        return nil;
    
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
        [dateFormatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    });
    
    return [dateFormatter stringFromDate:date];
}

- (void)dealloc{
}
@end

@implementation AYMediaWriterTool

+ (CMSampleBufferRef)PCMDataToSampleBuffer:(NSData *)pcmData pts:(CMTime)pts duration:(CMTime)duration{
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = 44100;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBytesPerPacket = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mReserved = 0;
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mData = (void *)pcmData.bytes;
    bufferList.mBuffers[0].mDataByteSize = (UInt32)pcmData.length;
    
    CMSampleTimingInfo timing;
    timing.presentationTimeStamp = pts;
    timing.duration = CMTimeMake(1, 44100);
    timing.decodeTimeStamp = kCMTimeInvalid;
    
    OSType error;
    
    CMAudioFormatDescriptionRef format;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, 0, 0, 0, 0, &format);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %u", (unsigned int)error);
        return NULL;
    }
    
    CMSampleBufferRef sampleBuffer;
    error = CMSampleBufferCreate(kCFAllocatorDefault, 0, 0, 0, 0, format, pcmData.length/2, 1, &timing, 0, 0, &sampleBuffer);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %u", (unsigned int)error);
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &bufferList);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %u", (unsigned int)error);
        return NULL;
    }
    
    CFRelease(format);
    
    return sampleBuffer;
}

@end
