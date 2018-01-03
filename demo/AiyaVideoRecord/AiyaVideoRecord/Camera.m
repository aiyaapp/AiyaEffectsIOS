//
//  Camera.m
//  AiyaVideoRecord
//
//  Created by 汪洋 on 2017/12/28.
//  Copyright © 2017年 深圳市哎吖科技有限公司. All rights reserved.
//

#import "Camera.h"

@interface Camera () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    dispatch_queue_t videoProcessingQueue, audioProcessingQueue;
    dispatch_semaphore_t frameRenderingSemaphore;
}

//捕获设备，摄像头
@property (nonatomic, strong) AVCaptureDevice *camera;

//捕获设备，麦克风（音频输入）
@property (nonatomic, strong) AVCaptureDevice *microphone;

//输入设备, 使用摄像头初始化
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

//输出设备, 输出视频数据 (CMSampleBufferRef)
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

//输入设备, 使用麦克风初始化
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

//输出设备, 输出音频数据 (CMSampleBufferRef)
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

//由他把输入输出结合在一起，并开始启动捕获设备（摄像头, 麦克风）
@property (nonatomic, strong) AVCaptureSession *session;

@end

@implementation Camera

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commitInit];
        [self configVideo];
        [self configAudio];
        [self configSession];
    }
    return self;
}

- (void)commitInit{
    frameRenderingSemaphore = dispatch_semaphore_create(1);
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ){
        if (device.position == AVCaptureDevicePositionFront){
            self.camera = device;
        }
    }
    
    self.microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:nil];
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.microphone error:nil];
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    self.session = [[AVCaptureSession alloc] init];
}

- (void)configVideo{
    videoProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [self.videoOutput setSampleBufferDelegate:self queue:videoProcessingQueue];
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
}

- (void)configAudio{
    audioProcessingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    [self.audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
}

- (void)configSession{
    
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]){
        self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    }else if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480]){
        self.session.sessionPreset = AVCaptureSessionPreset640x480;
    }
    
    [self.session commitConfiguration];
}

- (void)startCapture{
    if (![self.session isRunning]) {
        [self.session startRunning];
    }
}

- (void)stopCapture{
    if ([self.session isRunning]) {
        [self.session stopRunning];
    }
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (output == self.videoOutput){
        if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0) {
            return;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraVideoOutput:)]) {
            [self.delegate cameraVideoOutput:sampleBuffer];
        }
        
        dispatch_semaphore_signal(frameRenderingSemaphore);

    } else if (output == self.audioOutput){
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraAudioOutput:)]) {
            [self.delegate cameraAudioOutput:sampleBuffer];
        }
    }
}

#pragma mark 设置前后相机
- (void)setCameraPosition:(AVCaptureDevicePosition)position{
    BOOL isRuning = [self.session isRunning];
    
    if (isRuning) {
        [self stopCapture];
    }
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices ){
        if ( device.position == position ){
            self.camera = device;
        }
    }
    
    [self.session beginConfiguration];
    
    [self.session removeInput:self.videoInput];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:nil];

    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    [self.session commitConfiguration];

    if (isRuning) {
        [self startCapture];
    }
}

#pragma mark 设置帧率
- (void)setRate:(int)rate{
    if ([self.camera lockForConfiguration:nil]) {
        AVFrameRateRange *rateRange = self.camera.activeFormat.videoSupportedFrameRateRanges.lastObject;
        if (rateRange && [self.camera respondsToSelector:@selector(activeVideoMinFrameDuration)]) {
            [self.camera lockForConfiguration:nil];
            self.camera.activeVideoMinFrameDuration = CMTimeMake(1, rateRange.minFrameDuration.timescale < rate ? rateRange.minFrameDuration.timescale : rate);
            self.camera.activeVideoMaxFrameDuration = CMTimeMake(1, rateRange.minFrameDuration.timescale < rate ? rateRange.minFrameDuration.timescale : rate);
            [self.camera unlockForConfiguration];
        }
        
        [self.camera unlockForConfiguration];
    }
}

#pragma mark 设置手电筒
- (void)setTorchOn:(BOOL)torchMode{
    if ([self.camera lockForConfiguration:nil]) {
        if (torchMode) {
            if ([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
                [self.camera setTorchMode:AVCaptureTorchModeOn];
            }
        }else {
            if ([self.camera isTorchModeSupported:AVCaptureTorchModeOff]) {
                [self.camera setTorchMode:AVCaptureTorchModeOff];
            }
        }

        [self.camera unlockForConfiguration];
    }
}

#pragma mark 设置聚焦
- (void)focusAtPoint:(CGPoint)focusPoint{
    if ([self.camera lockForConfiguration:nil]) {
        //对焦模式和对焦点
        if ([self.camera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.camera setFocusPointOfInterest:focusPoint];
            [self.camera setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        //曝光模式和曝光点
        if ([self.camera isExposureModeSupported:AVCaptureExposureModeAutoExpose ]) {
            [self.camera setExposurePointOfInterest:focusPoint];
            [self.camera setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        
        [self.camera unlockForConfiguration];
    }
}
@end
