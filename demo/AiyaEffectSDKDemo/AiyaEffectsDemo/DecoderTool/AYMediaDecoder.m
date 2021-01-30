//
//  AYMediaDecoder.m
//  AiyaEffectsDemo
//
//  Created by 汪洋 on 2021/1/25.
//  Copyright © 2021 深圳哎吖科技. All rights reserved.
//

#import "AYMediaDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import "AYReadWriteLock.h"

@interface AYMediaDecoder ()

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) AVAssetReader *assetMediaReader;

@property (nonatomic, strong) AVAssetReaderOutput *assetReaderAudioOutput;
@property (nonatomic, strong) AVAssetReaderOutput *assetReaderVideoOutput;

@property (nonatomic, strong) dispatch_queue_t decoderQueue;
@property (nonatomic, strong) AYReadWriteLock *lock;

@property (nonatomic, assign) BOOL iCancel;

@end

@implementation AYMediaDecoder

- (id)init{
    self = [super init];
    if (self) {
        _decoderQueue = dispatch_queue_create("com.aiyaapp.video.decoder", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[AYReadWriteLock alloc] init];
    }
    return self;
}

- (void)setOutputMediaURL:(NSURL *)outputMediaURL completion:(void (^)(bool))completion {
    
    NSDictionary * inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    self.asset = [[AVURLAsset alloc] initWithURL:outputMediaURL options:inputOptions];

    __weak typeof(self) ws = self;
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        if ([ws.asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded) {
            NSError *outError;
            ws.assetMediaReader = [[AVAssetReader alloc] initWithAsset:self.asset error:&outError];
            if (outError == nil) {
                
                _iCancel = NO;
                if (completion != NULL) {
                    completion(true);
                }
            } else {
                if (completion != NULL) {
                    completion(false);
                }
            }
        } else {
            if (completion != NULL) {
                completion(false);
            }
        }
    }];
}

- (void)configureVideoDecoder {
    dispatch_async(_decoderQueue, ^{
        AVAssetTrack *assetVideoTrack = nil;
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0){
            assetVideoTrack = [videoTracks objectAtIndex:0];
        } else {
            NSLog(@"configure video decoder error : video track is null");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate decoderOutputVideoFormatWithWidth:0 height:0 videoFrameRate:0 transform:CGAffineTransformIdentity];
            });
            return;
        }
        
        NSDictionary *decompressionVideoSettings = @{
            (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
            (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
        };
        self.assetReaderVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetVideoTrack outputSettings:decompressionVideoSettings];
        [self.assetMediaReader addOutput:self.assetReaderVideoOutput];
        
        CGSize size = assetVideoTrack.naturalSize;
        NSUInteger frameRate = round(assetVideoTrack.nominalFrameRate);
        CGAffineTransform preferredTransform = assetVideoTrack.preferredTransform;
        
        if (self.delegate != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate decoderOutputVideoFormatWithWidth:size.width height:size.height videoFrameRate:frameRate transform:preferredTransform];
            });
        }
    });
}

- (void)configureAudioDecoder {
    dispatch_async(_decoderQueue, ^{
        AVAssetTrack *assetAudioTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0){
            assetAudioTrack = [audioTracks objectAtIndex:0];
        } else {
            NSLog(@"configure audio decoder error : audio track is null");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate decoderOutputAudioFormatWithChannelCount:0 sampleRate:0];
            });
            return;
        }
        
        NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
        self.assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
        [self.assetMediaReader addOutput:self.assetReaderAudioOutput];
        
        CMAudioFormatDescriptionRef format = (__bridge CMAudioFormatDescriptionRef)([assetAudioTrack formatDescriptions][0]);
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format);
        NSUInteger sampleRate = asbd->mSampleRate;
        NSUInteger channel = asbd->mChannelsPerFrame;
        
        if (self.delegate != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate decoderOutputAudioFormatWithChannelCount:channel sampleRate:sampleRate];
            });
        }
    });
}

- (void)start {
    if (self.assetMediaReader.status == AVAssetWriterStatusUnknown ) {
        if ([self.assetMediaReader startReading]) {
            // 视频解码
            dispatch_async(_decoderQueue, ^{
                BOOL completedOrFailed = NO;
                while (!completedOrFailed){
                    
                    [self.lock.readLock lock];
                    
                    if (self.iCancel) {
                        [self.lock.readLock unlock];
                        return;
                    }
                    
                    CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        if (self.delegate != NULL) {
                            [self.delegate decoderVideoOutput:sampleBuffer];
                        }
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                    }else{
                        completedOrFailed = YES;
                    }
                    
                    [self.lock.readLock unlock];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate != nil) {
                        [self.delegate decoderVideoEOS:YES];
                    }
                });
            });
            // 音频解码
            dispatch_async(_decoderQueue, ^{
                BOOL completedOrFailed = NO;
                while (!completedOrFailed){
                    
                    [self.lock.readLock lock];
                    
                    if (self.iCancel) {
                        [self.lock.readLock unlock];
                        return;
                    }
                    
                    CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        if (self.delegate != NULL) {
                            [self.delegate decoderAudioOutput:sampleBuffer];
                        }
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                    }else{
                        completedOrFailed = YES;
                    }
                    
                    [self.lock.readLock unlock];

                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.delegate != nil) {
                        [self.delegate decoderAudioEOS:YES];
                    }
                });
            });
        } else {
            if (self.delegate != nil) {
                [self.delegate decoderVideoEOS:NO];
                [self.delegate decoderAudioEOS:NO];
            }
        }
    } else {
        if (self.delegate != nil) {
            [self.delegate decoderVideoEOS:NO];
            [self.delegate decoderAudioEOS:NO];
        }
    }
}

- (void)cancelReading {
    [self.lock.writeLock lock];
    
    if (self.iCancel) {
        [self.lock.writeLock unlock];
        return;
    }
    
    self.iCancel = true;
    
    [self.assetMediaReader cancelReading];
    
    [self.lock.writeLock unlock];
}

+ (NSUInteger)preferredTransformToRotation:(CGAffineTransform)transform {
    
    if ([self compareTransformA:CGAffineTransformMakeRotation(0) transformB:transform]) {
        return 0;
    } else if ([self compareTransformA:CGAffineTransformMakeRotation(M_PI_2) transformB:transform]) {
        return 90;
    } else if ([self compareTransformA:CGAffineTransformMakeRotation(M_PI) transformB:transform]) {
        return 180;
    } else if ([self compareTransformA:CGAffineTransformMakeRotation(M_PI_2+M_PI) transformB:transform]) {
        return 270;
    }
    
    return 0;
}

+ (BOOL)compareTransformA:(CGAffineTransform)transformA transformB:(CGAffineTransform)transformB {
    BOOL result = roundf(transformA.a) == roundf(transformB.a)
        && roundf(transformA.b) == roundf(transformB.b)
        && roundf(transformA.c) == roundf(transformB.c)
    && roundf(transformA.d) == roundf(transformB.d);
    
    return result;
}

@end
