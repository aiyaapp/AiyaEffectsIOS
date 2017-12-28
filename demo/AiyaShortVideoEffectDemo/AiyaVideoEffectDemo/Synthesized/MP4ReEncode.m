
#import "MP4ReEncode.h"

@interface MP4ReEncode()
{
    dispatch_queue_t _mainSerializationQueue;
    dispatch_queue_t _rwAudioSerializationQueue;
    dispatch_queue_t _rwVideoSerializationQueue;
    
    dispatch_group_t _dispatchGroup;
}

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, assign) BOOL cancelled;

@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetReaderOutput *assetReaderAudioOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;

@property (nonatomic, strong) AVAssetReaderOutput *assetReaderVideoOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;

@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;


@end

@implementation MP4ReEncode
{
    unsigned int _bitrate;
}

- (id)init
{
    self = [super init];
    if(self!= nil){
        _bitrate = 2 * 1024 * 1024;
    }
    return self;
}

- (void) SetBitrate:(unsigned int)bitrate
{
    _bitrate = bitrate;
}

- (void)initSetup
{
    // Create the main serialization queue.
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    _mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    
    // Create the serialization queue to use for reading and writing the audio data.
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    _rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);
    
    // Create the serialization queue to use for reading and writing the video data.
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];
    _rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], NULL);
}

- (void)startReencode
{
    
    NSDictionary * inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    
    self.asset = [[AVURLAsset alloc] initWithURL:self.inputURL options:inputOptions];;
    self.cancelled = NO;
    // Asynchronously load the tracks of the asset you want to read.
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
        // Once the tracks have finished loading, dispatch the work to the main serialization queue.
        dispatch_async(_mainSerializationQueue, ^{
            // Due to asynchronous nature, check to see if user has already cancelled.
            if (self.cancelled){
                return;
            }
            
            BOOL success = YES;
            NSError *localError = nil;
            // Check for success of loading the assets tracks.
            success = ([self.asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
            if (success){
                // If the tracks loaded successfully, make sure that no file exists at the output path for the asset writer.
                NSFileManager *fm = [NSFileManager defaultManager];
                NSString *localOutputPath = [self.outputURL path];
                if ([fm fileExistsAtPath:localOutputPath]){
                    success = [fm removeItemAtPath:localOutputPath error:&localError];
                }
            }
            if (success){
                success = [self setupAssetReaderAndAssetWriter:&localError];
            }
            if (success){
                success = [self startAssetReaderAndWriter:&localError];
            }
            if (!success){
                [self readingAndWritingDidFinishSuccessfully:success withError:localError];
            }
        });
    }];
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError
{
    // Create and initialize the asset reader.
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = (self.assetReader != nil);
    if (success){
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:AVFileTypeQuickTimeMovie error:outError];
        success = (self.assetWriter != nil);
    }
    
    if (success){
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil, *assetVideoTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0){
            assetAudioTrack = [audioTracks objectAtIndex:0];
        }
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0){
            assetVideoTrack = [videoTracks objectAtIndex:0];
        }
        
        if (assetAudioTrack){
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            self.assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
            [self.assetReader addOutput:self.assetReaderAudioOutput];
            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            NSDictionary *compressionAudioSettings = @{
                                                       AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                                       AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                                                       AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                                                       AVChannelLayoutKey    : channelLayoutAsData,
                                                       AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
                                                       };
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        
        if (assetVideoTrack){
            // If there is a video track to read, set the decompression settings for YUV and create the asset reader output.
            NSDictionary *decompressionVideoSettings = @{
                                                         (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange],
                                                         (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
                                                         };
            self.assetReaderVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetVideoTrack outputSettings:decompressionVideoSettings];
            [self.assetReader addOutput:self.assetReaderVideoOutput];
            CMFormatDescriptionRef formatDescription = NULL;
            // Grab the video format descriptions from the video track and grab the first one if it exists.
            NSArray *videoFormatDescriptions = [assetVideoTrack formatDescriptions];
            if ([videoFormatDescriptions count] > 0){
                formatDescription = (__bridge CMFormatDescriptionRef)[videoFormatDescriptions objectAtIndex:0];
            }
            //            CGSize trackDimensions = {
            //                .width = 0.0,
            //                .height = 0.0,
            //            };
            //            // If the video track had a format description, grab the track dimensions from there. Otherwise, grab them direcly from the track itself.
            //            if (formatDescription)
            //                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            //            else
            //                trackDimensions = [assetVideoTrack naturalSize];
            
            CGSize outputSize  = [assetVideoTrack naturalSize];
            CGAffineTransform transform = [assetVideoTrack preferredTransform];
            
            if (self.delegate) {
                [self.delegate MP4ReEncodeVideoParamWithNaturalSize:&outputSize preferredTransform:&transform];
            }
            
            NSMutableDictionary *compressionSettings = [NSMutableDictionary dictionary];
            // If the video track had a format description, attempt to grab the clean aperture settings and pixel aspect ratio used by the video.
            if (formatDescription){
                NSDictionary *cleanAperture = nil;
                NSDictionary *pixelAspectRatio = nil;
                CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
                if (cleanApertureFromCMFormatDescription){
                    cleanAperture = @{
                                      AVVideoCleanApertureWidthKey            : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureWidth),
                                      AVVideoCleanApertureHeightKey           : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight),
                                      AVVideoCleanApertureHorizontalOffsetKey : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                                      AVVideoCleanApertureVerticalOffsetKey   : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset)
                                      };
                }
                CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
                if (pixelAspectRatioFromCMFormatDescription){
                    pixelAspectRatio = @{
                                         AVVideoPixelAspectRatioHorizontalSpacingKey : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                                         AVVideoPixelAspectRatioVerticalSpacingKey   : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
                                         };
                }
                // Add whichever settings we could grab from the format description to the compression settings dictionary.
                if (cleanAperture || pixelAspectRatio){
                    NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
                    if (cleanAperture){
                        [mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
                    }
                    if (pixelAspectRatio){
                        [mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
                    }
                    compressionSettings = mutableCompressionSettings;
                }
            }
            
            [compressionSettings setObject:[NSNumber numberWithInteger: _bitrate] forKey:AVVideoAverageBitRateKey];
            [compressionSettings setObject:AVVideoProfileLevelH264High41 forKey:AVVideoProfileLevelKey];
            
            // Create the video settings dictionary for H.264.
            NSMutableDictionary *videoSettings = [@{
                                                                           AVVideoCodecKey  : AVVideoCodecH264,
                                                                           AVVideoWidthKey  : [NSNumber numberWithDouble:outputSize.width],
                                                                           AVVideoHeightKey : [NSNumber numberWithDouble:outputSize.height]
                                                                           } mutableCopy];
            // Put the compression settings into the video settings dictionary if we were able to grab them.
            if (compressionSettings){
                [videoSettings setObject:compressionSettings forKey:AVVideoCompressionPropertiesKey];
            }
            // Create the asset writer input and add it to the asset writer.
            self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetVideoTrack mediaType] outputSettings:videoSettings];
            self.assetWriterVideoInput.transform = transform;
            
            [self.assetWriter addInput:self.assetWriterVideoInput];
            
        }
    }
    return success;
}

//- (bool)writer:(CMSampleBufferRef)sampleBuffer FirstFrame:(bool)firstFrame
//{
//    BOOL success = FALSE;
//    if([self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]){
//        success = TRUE;
//    }
//
//    return success;
//}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError
{
    BOOL success = YES;
    // Attempt to start the asset reader.
    success = [self.assetReader startReading];
    if (!success){
        *outError = [self.assetReader error];
    }
    if (success){
        // If the reader started successfully, attempt to start the asset writer.
        success = [self.assetWriter startWriting];
        if (!success)
            *outError = [self.assetWriter error];
    }
    
    if (success){
        // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
        _dispatchGroup = dispatch_group_create();
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        self.audioFinished = NO;
        self.videoFinished = NO;
        
        if (self.assetWriterAudioInput){
            // If there is audio to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(_dispatchGroup);
            // Specify the block to execute when the asset writer is ready for audio media data, and specify the queue to call it on.
            [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:_rwAudioSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.audioFinished){
                    return;
                }
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed){
                    // Get the next audio sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL)
                    {
                        BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    }else{
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed){
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
                    BOOL oldFinished = self.audioFinished;
                    self.audioFinished = YES;
                    if (oldFinished == NO)
                    {
                        [self.assetWriterAudioInput markAsFinished];
                    }
                    dispatch_group_leave(_dispatchGroup);
                }
            }];
        }
        
        if (self.assetWriterVideoInput){
            // If we had video to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(_dispatchGroup);
            // Specify the block to execute when the asset writer is ready for video media data, and specify the queue to call it on.
            [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:_rwVideoSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.videoFinished){
                    return;
                }
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed){
                    // Get the next video sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL){
                        if(self.delegate){
                            sampleBuffer = [self.delegate MP4ReEncodeProcessVideoSampleBuffer:sampleBuffer];
                        }
                        
                        BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                        
                    }else{
                        completedOrFailed = YES;
                    }
                }
                if(completedOrFailed){
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the video work has finished).
                    BOOL oldFinished = self.videoFinished;
                    self.videoFinished = YES;
                    if (oldFinished == NO){
                        [self.assetWriterVideoInput markAsFinished];
                    }
                    dispatch_group_leave(_dispatchGroup);
                }
            }];
        }
        // Set up the notification that the dispatch group will send when the audio and video work have both finished.
        dispatch_group_notify(_dispatchGroup, _mainSerializationQueue, ^{
            BOOL finalSuccess = YES;
            NSError *finalError = nil;
            // Check to see if the work has finished due to cancellation.
            if (self.cancelled){
                // If so, cancel the reader and writer.
                [self.assetReader cancelReading];
                [self.assetWriter cancelWriting];
            }else{
                // If cancellation didn't occur, first make sure that the asset reader didn't fail.
                if ([self.assetReader status] == AVAssetReaderStatusFailed){
                    finalSuccess = NO;
                    finalError = [self.assetReader error];
                }
                // If the asset reader didn't fail, attempt to stop the asset writer and check for any errors.
                if (finalSuccess){
                    finalSuccess = [self.assetWriter finishWriting];
                    if (!finalSuccess){
                        finalError = [self.assetWriter error];
                    }
                }
            }
            // Call the method to handle completion, and pass in the appropriate parameters to indicate whether reencoding was successful.
            [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
        });
    }
    // Return success here to indicate whether the asset reader and writer were started successfully.
    return success;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
    if (!success){
        // If the reencoding process failed, we need to cancel the asset reader and writer.
        [self.assetReader cancelReading];
        [self.assetWriter cancelWriting];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to failure.
        });
    }else{
        // Reencoding was successful, reset booleans.
        self.cancelled = NO;
        self.videoFinished = NO;
        self.audioFinished = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Handle any UI tasks here related to success.
            NSLog(@"转换ok");
            UISaveVideoAtPathToSavedPhotosAlbum([_outputURL relativePath], nil, nil, nil);
            
            if (self.delegate) {
                [self.delegate MP4ReEncodeFinish:success];
            }
        });
    }

}

- (void)cancel
{
    // Handle cancellation asynchronously, but serialize it with the main queue.
    dispatch_async(_mainSerializationQueue, ^{
        // If we had audio data to reencode, we need to cancel the audio work.
        if (self.assetWriterAudioInput)
        {
            // Handle cancellation asynchronously again, but this time serialize it with the audio queue.
            dispatch_async(_rwAudioSerializationQueue, ^{
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.audioFinished;
                self.audioFinished = YES;
                if (oldFinished == NO)
                {
                    [self.assetWriterAudioInput markAsFinished];
                }
                // Leave the dispatch group since the audio work is finished now.
                dispatch_group_leave(_dispatchGroup);
            });
        }
        
        if (self.assetWriterVideoInput)
        {
            // Handle cancellation asynchronously again, but this time serialize it with the video queue.
            dispatch_async(_rwVideoSerializationQueue, ^{
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.videoFinished;
                self.videoFinished = YES;
                if (oldFinished == NO)
                {
                    [self.assetWriterVideoInput markAsFinished];
                }
                // Leave the dispatch group, since the video work is finished now.
                dispatch_group_leave(_dispatchGroup);
            });
        }
        // Set the cancelled Boolean property to YES to cancel any work on the main queue as well.
        self.cancelled = YES;
    });
}

@end

