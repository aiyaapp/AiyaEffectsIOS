#import "MediaWriter.h"

#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface MediaWriter (){
    dispatch_queue_t writerQueue; // AVAssetWriter 不能并行调用, 会出错.
    
    CMFormatDescriptionRef _outputFormatDescription;
}

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, assign) BOOL videoAlreadySetup;
@property (nonatomic, assign) BOOL audioAlreadySetup;
@property (nonatomic, assign) BOOL isFinish;

@property (atomic, assign) BOOL canStartWrite;
@property (atomic, assign) BOOL hasFirstFrameTime;

@property (nonatomic, assign) CMTime firstTime;
@end

@implementation MediaWriter

#pragma mark - init

// 音频的码率
static const int kAudioBitRate = 64000;

// 视频的码率
static const int kVideoBitRateFactor = 4; // videoBitRate = width * height * kVideoBitRateFactor;

// 帧率
static const int kVideoFrameRate = 30;

// 画面旋转方向
static const float radian = M_PI_2;

- (id)init{
    self = [super init];
    if (self) {
        writerQueue = dispatch_queue_create("com.aiyaapp.aiya.videocrecord", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setOutputURL:(NSURL *)outputURL{
    _outputURL = outputURL;
    
    NSError *error = nil;
    _assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:(NSString *)kUTTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"error setting up the asset writer (%@)", error);
        self.assetWriter = nil;
        return;
    }
    
    self.assetWriter.shouldOptimizeForNetworkUse = YES;
    self.assetWriter.metadata = [self _metadataArray];
    
    _videoAlreadySetup = NO;
    _audioAlreadySetup = NO;
    _isFinish = NO;
    _canStartWrite = NO;
    _hasFirstFrameTime = NO;
}

#pragma mark - private

- (NSArray *)_metadataArray{
    
    UIDevice *currentDevice = [UIDevice currentDevice];

    // device model
    AVMutableMetadataItem *modelItem = [[AVMutableMetadataItem alloc] init];
    [modelItem setKeySpace:AVMetadataKeySpaceCommon];
    [modelItem setKey:AVMetadataCommonKeyModel];
    [modelItem setValue:[currentDevice localizedModel]];

    // software
    AVMutableMetadataItem *softwareItem = [[AVMutableMetadataItem alloc] init];
    [softwareItem setKeySpace:AVMetadataKeySpaceCommon];
    [softwareItem setKey:AVMetadataCommonKeySoftware];
    [softwareItem setValue:@"AiyaCamera"];

    // creation date
    AVMutableMetadataItem *creationDateItem = [[AVMutableMetadataItem alloc] init];
    [creationDateItem setKeySpace:AVMetadataKeySpaceCommon];
    [creationDateItem setKey:AVMetadataCommonKeyCreationDate];
    [creationDateItem setValue:[MediaWriter AiyaVideoFormattedTimestampStringFromDate:[NSDate date]]];

    return @[modelItem, softwareItem, creationDateItem];
}

#pragma mark - setup

- (BOOL)setupAudioWithSettings:(CMSampleBufferRef)sampleBuffer{
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (!asbd) {
        NSLog(@"audio stream description used with non-audio format description");
        return NO;
    }
    
    double sampleRate = asbd->mSampleRate;
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
    NSData *currentChannelLayoutData = ( currentChannelLayout && aclSize > 0 ) ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                AVNumberOfChannelsKey : @(2),
                                                AVSampleRateKey :  @(sampleRate),
                                                AVEncoderBitRateKey : @(kAudioBitRate),
                                                AVChannelLayoutKey : currentChannelLayoutData };
    
    if (!self.assetWriterAudioInput && [self.assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {

        self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;

        if (self.assetWriterAudioInput && [self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
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

- (BOOL)setupVideoWithSettings:(CVImageBufferRef)pixelBuffer {
    
    CMFormatDescriptionRef outputFormatDescription = NULL;

    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, &outputFormatDescription );
    _outputFormatDescription = outputFormatDescription;
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                     AVVideoWidthKey : @(width),
                                     AVVideoHeightKey : @(height),
                                     AVVideoCompressionPropertiesKey : @{
                                             AVVideoAverageBitRateKey : @(width * height * kVideoBitRateFactor),
                                             AVVideoExpectedSourceFrameRateKey : @(kVideoFrameRate),
                                             AVVideoMaxKeyFrameIntervalKey : @(kVideoFrameRate)
                                             }
                                    };
    
    if (!self.assetWriterVideoInput && [self.assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {

        self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(radian);
        
        if (self.assetWriterVideoInput && [self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
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

    return YES;
}

#pragma mark - sample buffer writing

- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (self.isFinish) {
        return;
    }
    
    if (!self.audioAlreadySetup){
        dispatch_sync(writerQueue, ^{
            self.audioAlreadySetup = [self setupAudioWithSettings:sampleBuffer];
        });
        
        if (!self.audioAlreadySetup) {
            NSLog(@"设置音频参数失败");
            return;
        } else {
            NSLog(@"设置音频参数成功");
        }
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }

    // setup the writer
    if ( self.assetWriter.status == AVAssetWriterStatusUnknown ) {
        NSLog(@"audio writer unknown");
        return;
    }

    // check for completion state
    if ( self.assetWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"audio writer failure, (%@)", self.assetWriter.error.localizedDescription);
        return;
    }

    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"audio writer cancelled");
        return;
    }

    if ( self.assetWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }

    // perform write
    if ( self.assetWriter.status == AVAssetWriterStatusWriting && _canStartWrite && self.hasFirstFrameTime) {
        
        CFRetain(sampleBuffer);
        
        dispatch_async(writerQueue, ^{
            if (self.assetWriterAudioInput && self.assetWriterAudioInput.readyForMoreMediaData) {
                
                CMSampleBufferRef adjustedSampleBuffer = [self adjustTime:sampleBuffer by:self.firstTime];

                if (adjustedSampleBuffer ) {
                    if (![self.assetWriterAudioInput appendSampleBuffer:adjustedSampleBuffer]) {
                        NSLog(@"audio writer error appending audio (%@)", self.assetWriter.error);
                    }else {
//                        NSLog(@"audio write success");
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

- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime{
    if (self.isFinish) {
        return;
    }
    
    if (!self.videoAlreadySetup){
        dispatch_sync(writerQueue, ^{
            self.videoAlreadySetup = [self setupVideoWithSettings:pixelBuffer];
        });
        
        if (!self.videoAlreadySetup){
            NSLog(@"设置视频参数失败");
            return;
        } else {
            NSLog(@"设置视频参数成功");
        }
    }
        
    if ( self.assetWriter.status == AVAssetWriterStatusUnknown ) {
        
        dispatch_async(writerQueue, ^{
            if (!self.canStartWrite){
                //开始视频录制
                if ([self.assetWriter startWriting]) {
                    self.canStartWrite = YES;
                } else {
                    NSLog(@"audio error when starting to write (%@)", [self.assetWriter error]);
                }
            }
        });
    }
    
    // check for completion state
    if ( self.assetWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"video writer failure, (%@)", self.assetWriter.error.localizedDescription);
        return;
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"video writer cancelled");
        return;
    }
    
    if ( self.assetWriter.status == AVAssetWriterStatusCompleted) {
        NSLog(@"video writer completed");
        return;
    }
    
    // perform write
    if ( self.assetWriter.status == AVAssetWriterStatusWriting && _canStartWrite) {
        if (!self.canStartWrite) {
            NSLog(@"video canStartWrite");
        }
        
        if ([self.assetWriterVideoInput isReadyForMoreMediaData]) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);

            dispatch_async(writerQueue, ^{
                if (self.isFinish){
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
                    return;
                }
                
                CMTime videoTime;
                
                if (!self.hasFirstFrameTime) {
                    
                    self.firstTime = frameTime;
                    
                    videoTime = kCMTimeZero;
                    [self.assetWriter startSessionAtSourceTime:videoTime];
                    self.hasFirstFrameTime = YES;
                    NSLog(@"设置第一帧的时间");
                }else {
                    videoTime = CMTimeSubtract(frameTime, self.firstTime);
                }
                
                CMSampleBufferRef adjustedSampleBuffer = NULL;
                
                CMSampleTimingInfo timingInfo = {0,};
                timingInfo.duration = kCMTimeInvalid;
                timingInfo.decodeTimeStamp = kCMTimeInvalid;
                timingInfo.presentationTimeStamp = videoTime;
                
                CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, _outputFormatDescription, &timingInfo, &adjustedSampleBuffer );
                
                if ( adjustedSampleBuffer ) {
                    if (![self.assetWriterVideoInput appendSampleBuffer:adjustedSampleBuffer]){
                        NSLog(@"video writer error appending video (%@)", self.assetWriter.error);
                    }else {
//                        NSLog(@"video write success");
                    }
                    
                    CFRelease( adjustedSampleBuffer );
                }
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            });
        }
    }
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler{
    dispatch_async(writerQueue, ^{//等待数据全部完成写入
        if (self.isFinish) {
            return;
        }
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
            self.assetWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset writer was in an unexpected state (%@)", @(self.assetWriter.status));
            return;
        }
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];
        [self.assetWriter finishWritingWithCompletionHandler:handler];
        
        self.assetWriterVideoInput = nil;
        self.assetWriterAudioInput = nil;
        self.assetWriter = nil;
        
    });
}

- (void)cancelWriting{
    dispatch_async(writerQueue, ^{//等待数据全部完成写入
        if (self.isFinish) {
            return;
        }
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
            self.assetWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset writer was in an unexpected state (%@)", @(self.assetWriter.status));
            return;
        }
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];
        [self.assetWriter cancelWriting];
        
        self.assetWriterAudioInput = nil;
        self.assetWriterVideoInput = nil;
        self.assetWriter = nil;
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
