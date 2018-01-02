#import "MediaWriter.h"

#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface MediaWriter (){
    dispatch_queue_t _videoQueue;
    
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

- (id)init{
    self = [super init];
    if (self) {
        //缓存两帧
        _videoQueue = dispatch_queue_create("com.aiyaapp.aiya.videocrecord", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)setOutputURL:(NSURL *)outputURL{
    _outputURL = outputURL;
    
    NSError *error = nil;
    _assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:(NSString *)kUTTypeMPEG4 error:&error];
    if (error) {
        DDLogError(@"error setting up the asset writer (%@)", error);
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
        DDLogError(@"audio stream description used with non-audio format description");
        return NO;
    }
    
    double sampleRate = asbd->mSampleRate;
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
    NSData *currentChannelLayoutData = ( currentChannelLayout && aclSize > 0 ) ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                AVNumberOfChannelsKey : @(2),
                                                AVSampleRateKey :  @(sampleRate),
                                                AVEncoderBitRateKey : @(64000),
                                                AVChannelLayoutKey : currentChannelLayoutData };
    
    if (!self.assetWriterAudioInput && [self.assetWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {

        self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;

        if (self.assetWriterAudioInput && [self.assetWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetWriter addInput:self.assetWriterAudioInput];
        } else {
            DDLogError(@"couldn't add asset writer audio input");
        }

    } else {

        self.assetWriterAudioInput = nil;
        DDLogError(@"couldn't apply audio output settings");

    }

    return YES;
}

- (BOOL)setupVideoWithSettings:(CVImageBufferRef)pixelBuffer {
    
    CMFormatDescriptionRef outputFormatDescription = NULL;

    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, &outputFormatDescription );
    _outputFormatDescription = outputFormatDescription;
    
    NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                     AVVideoWidthKey : @(720),
                                     AVVideoHeightKey : @(1280),
                                     AVVideoCompressionPropertiesKey : @{
                                             AVVideoAverageBitRateKey : @(720 * 1280 * 2.05),
                                             AVVideoExpectedSourceFrameRateKey : @(30),
                                             AVVideoMaxKeyFrameIntervalKey : @(30)
                                             }
                                    };
    
    if (!self.assetWriterVideoInput && [self.assetWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {

        self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = CGAffineTransformIdentity;
        
        if (self.assetWriterVideoInput && [self.assetWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
        } else {
            DDLogError(@"couldn't add asset writer video input");
        }

    } else {

        self.assetWriterVideoInput = nil;
        DDLogError(@"couldn't apply video output settings");

    }

    return YES;
}

#pragma mark - sample buffer writing

- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (self.isFinish) {
        return;
    }
    
    if (!self.audioAlreadySetup){
        self.audioAlreadySetup = [self setupAudioWithSettings:sampleBuffer];
        DDLogInfo(@"设置音频参数");

        if (!self.audioAlreadySetup) {
            return;
        }
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }

    // setup the writer
    if ( self.assetWriter.status == AVAssetWriterStatusUnknown ) {
        DDLogError(@"audio writer unknown");
        return;
    }

    // check for completion state
    if ( self.assetWriter.status == AVAssetWriterStatusFailed ) {
        DDLogError(@"audio writer failure, (%@)", self.assetWriter.error.localizedDescription);
        return;
    }

    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        DDLogError(@"audio writer cancelled");
        return;
    }

    if ( self.assetWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }

    // perform write
    if ( self.assetWriter.status == AVAssetWriterStatusWriting && _canStartWrite && self.hasFirstFrameTime) {
        
        sampleBuffer = [self adjustTime:sampleBuffer by:self.firstTime];
        
        if (self.assetWriterAudioInput.readyForMoreMediaData) {
            if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                DDLogError(@"audio writer error appending audio (%@)", self.assetWriter.error);
            }
        }
        
        CFRelease(sampleBuffer);
    }
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++){
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
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
        self.videoAlreadySetup = [self setupVideoWithSettings:pixelBuffer];
        DDLogInfo(@"设置视频参数");
        if (!self.videoAlreadySetup){
            return;
        }
    }
        
    if ( self.assetWriter.status == AVAssetWriterStatusUnknown ) {
        
        dispatch_async(_videoQueue, ^{
            if (!self.canStartWrite){
                //开始视频录制
                if ([self.assetWriter startWriting]) {
                    self.canStartWrite = YES;
                } else {
                    DDLogError(@"audio error when starting to write (%@)", [self.assetWriter error]);
                }
            }
        });
    }
    
    // check for completion state
    if ( self.assetWriter.status == AVAssetWriterStatusFailed ) {
        DDLogError(@"video writer failure, (%@)", self.assetWriter.error.localizedDescription);
        return;
    }
    
    if (self.assetWriter.status == AVAssetWriterStatusCancelled) {
        DDLogError(@"video writer cancelled");
        return;
    }
    
    if ( self.assetWriter.status == AVAssetWriterStatusCompleted) {
        DDLogError(@"video writer completed");
        return;
    }
    
    // perform write
    if ( self.assetWriter.status == AVAssetWriterStatusWriting && _canStartWrite) {
        if (!self.canStartWrite) {
            DDLogError(@"video canStartWrite");
        }
        
        if ([self.assetWriterVideoInput isReadyForMoreMediaData]) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);

            dispatch_sync(_videoQueue, ^{
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
                    DDLogInfo(@"设置第一帧的时间");
                }else {
                    videoTime = CMTimeSubtract(frameTime, self.firstTime);
                }
                
                CMSampleBufferRef sampleBuffer = NULL;
                
                CMSampleTimingInfo timingInfo = {0,};
                timingInfo.duration = kCMTimeInvalid;
                timingInfo.decodeTimeStamp = kCMTimeInvalid;
                timingInfo.presentationTimeStamp = videoTime;
                
                CMSampleBufferCreateForImageBuffer( kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, _outputFormatDescription, &timingInfo, &sampleBuffer );
                if ( sampleBuffer ) {
                    [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                    CFRelease( sampleBuffer );
                }
                
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            });
        }
    }
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler{
    dispatch_sync(_videoQueue, ^{//等待数据全部完成写入
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
            self.assetWriter.status == AVAssetWriterStatusCompleted) {
            DDLogError(@"asset writer was in an unexpected state (%@)", @(self.assetWriter.status));
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
    dispatch_sync(_videoQueue, ^{//等待数据全部完成写入
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
            self.assetWriter.status == AVAssetWriterStatusCompleted) {
            DDLogError(@"asset writer was in an unexpected state (%@)", @(self.assetWriter.status));
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
    DDLogMethod();
}
@end
